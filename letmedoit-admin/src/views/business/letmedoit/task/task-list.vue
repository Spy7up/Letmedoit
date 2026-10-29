<!--
  * 让我做 · 任务管理
  * 数据来源：POST /task/query
  * 逾期是派生条件：未结束（状态 1/2）且已过截止时间，不是持久化状态
-->
<template>
  <a-form class="smart-query-form">
    <a-row class="smart-query-form-row" :gutter="12">
      <a-form-item label="关键字" class="smart-query-form-item">
        <a-input style="width: 220px" v-model:value="queryForm.searchWord" placeholder="任务标题 / 委托人 / 任务ID" allow-clear @pressEnter="onSearch" />
      </a-form-item>

      <a-form-item label="任务状态" class="smart-query-form-item">
        <a-select style="width: 140px" v-model:value="queryForm.status" placeholder="全部状态" allow-clear>
          <a-select-option v-for="item in statusOptionList" :key="item.value" :value="item.value">{{ item.desc }}</a-select-option>
        </a-select>
      </a-form-item>

      <a-form-item label="逾期" class="smart-query-form-item">
        <a-radio-group v-model:value="overdueValue" @change="onSearch">
          <a-radio-button :value="undefined">全部</a-radio-button>
          <a-radio-button :value="true">仅逾期</a-radio-button>
          <a-radio-button :value="false">未逾期</a-radio-button>
        </a-radio-group>
      </a-form-item>

      <a-form-item label="创建时间" class="smart-query-form-item">
        <a-range-picker v-model:value="createDateRange" value-format="YYYY-MM-DD" :placeholder="['开始日期', '结束日期']" />
      </a-form-item>

      <a-form-item class="smart-query-form-item">
        <a-button-group>
          <a-button type="primary" @click="onSearch" v-privilege="'task:query'">
            <template #icon>
              <SearchOutlined />
            </template>
            查询
          </a-button>
          <a-button @click="resetQuery" v-privilege="'task:query'">
            <template #icon>
              <ReloadOutlined />
            </template>
            重置
          </a-button>
        </a-button-group>
      </a-form-item>
    </a-row>
  </a-form>

  <a-card size="small" :bordered="false" :hoverable="true">
    <a-row class="smart-table-btn-block">
      <div class="smart-table-operate-block">
        <span class="letmedoit-table-tip">共 {{ total }} 个任务 · 首版为只读报表，不提供状态修改</span>
      </div>
      <div class="smart-table-setting-block">
        <TableOperator v-model="columns" :tableId="TABLE_ID_CONST.BUSINESS.LETMEDOIT.TASK" :refresh="queryData" />
      </div>
    </a-row>

    <a-table
      size="small"
      :dataSource="tableData"
      :columns="columns"
      rowKey="taskId"
      :scroll="{ x: 1200 }"
      bordered
      :loading="tableLoading"
      :pagination="false"
      @resizeColumn="handleResizeColumn"
    >
      <template #bodyCell="{ text, record, column }">
        <template v-if="column.dataIndex === 'title'">
          <a @click="toDetail(record.taskId)">{{ text }}</a>
          <div class="sub-text">#{{ record.taskId }}</div>
        </template>
        <template v-if="column.dataIndex === 'status'">
          <a-tag :color="statusColor(text)">{{ statusLabel(text) }}</a-tag>
        </template>
        <template v-if="column.dataIndex === 'completionMode'">
          {{ completionModeLabel(text) }}
        </template>
        <template v-if="column.dataIndex === 'progress'">
          <span>已接受 {{ record.acceptedCount }}/{{ record.participantCount }}</span>
          <div class="sub-text">已完成 {{ record.completedCount }}</div>
        </template>
        <template v-if="column.dataIndex === 'overdueFlag'">
          <a-tag v-if="record.overdueFlag" color="red">已逾期</a-tag>
          <span v-else class="sub-text">--</span>
        </template>
        <template v-if="column.dataIndex === 'action'">
          <div class="smart-table-operate">
            <a-button type="link" size="small" @click="toDetail(record.taskId)" v-privilege="'task:query'">详情</a-button>
          </div>
        </template>
      </template>
    </a-table>

    <div class="smart-query-table-page">
      <a-pagination
        showSizeChanger
        showQuickJumper
        show-less-items
        :pageSizeOptions="PAGE_SIZE_OPTIONS"
        :defaultPageSize="queryForm.pageSize"
        v-model:current="queryForm.pageNum"
        v-model:pageSize="queryForm.pageSize"
        :total="total"
        @change="queryData"
        :show-total="(total) => `共${total}条`"
      />
    </div>
  </a-card>
</template>

<script setup>
  import { ReloadOutlined, SearchOutlined } from '@ant-design/icons-vue';
  import _ from 'lodash';
  import { onMounted, reactive, ref } from 'vue';
  import { useRouter } from 'vue-router';
  import { letmedoitTaskApi } from '/@/api/business/letmedoit/task-api';
  import TableOperator from '/@/components/support/table-operator/index.vue';
  import { PAGE_SIZE_OPTIONS } from '/@/constants/common-const';
  import {
    TASK_COMPLETION_MODE_ENUM,
    TASK_STATUS_COLOR,
    TASK_STATUS_ENUM,
  } from '/@/constants/business/letmedoit/task-const';
  import { TABLE_ID_CONST } from '/@/constants/support/table-id-const';
  import { smartSentry } from '/@/lib/smart-sentry';

  const router = useRouter();

  const statusOptionList = Object.values(TASK_STATUS_ENUM);

  const columns = ref([
    { title: '任务', dataIndex: 'title', width: 240, resizable: true },
    { title: '委托人', dataIndex: 'creatorNickname', width: 140, resizable: true },
    { title: '状态', dataIndex: 'status', width: 100, resizable: true },
    { title: '完成条件', dataIndex: 'completionMode', width: 110, resizable: true },
    { title: '参与进度', dataIndex: 'progress', width: 130, resizable: true },
    { title: '截止时间', dataIndex: 'deadline', width: 170, resizable: true },
    { title: '逾期', dataIndex: 'overdueFlag', width: 90, resizable: true },
    { title: '创建时间', dataIndex: 'createTime', width: 170, resizable: true },
    { title: '操作', dataIndex: 'action', width: 90, fixed: 'right', resizable: true },
  ]);

  function handleResizeColumn(w, col) {
    columns.value.forEach((item) => {
      if (item.dataIndex === col.dataIndex) {
        item.width = Math.floor(w);
        item.dragAndDropFlag = true;
      }
    });
  }

  function statusLabel(status) {
    const target = Object.values(TASK_STATUS_ENUM).find((item) => item.value === status);
    return target ? target.desc : `状态 ${status}`;
  }

  function statusColor(status) {
    return TASK_STATUS_COLOR[status] || 'default';
  }

  function completionModeLabel(value) {
    const target = Object.values(TASK_COMPLETION_MODE_ENUM).find((item) => item.value === value);
    return target ? target.desc : '--';
  }

  const queryFormState = {
    searchWord: '',
    status: undefined,
    overdueFlag: undefined,
    beginDate: undefined,
    endDate: undefined,
    pageNum: 1,
    pageSize: 10,
    sortItemList: [],
  };

  const queryForm = reactive(_.cloneDeep(queryFormState));
  const createDateRange = ref([]);
  const overdueValue = ref(undefined);
  const tableLoading = ref(false);
  const tableData = ref([]);
  const total = ref(0);

  function onSearch() {
    queryForm.pageNum = 1;
    queryData();
  }

  function resetQuery() {
    const pageSize = queryForm.pageSize;
    Object.assign(queryForm, _.cloneDeep(queryFormState));
    queryForm.pageSize = pageSize;
    createDateRange.value = [];
    overdueValue.value = undefined;
    queryData();
  }

  async function queryData() {
    const range = createDateRange.value || [];
    queryForm.beginDate = range[0] || undefined;
    queryForm.endDate = range[1] || undefined;
    queryForm.overdueFlag = overdueValue.value;

    tableLoading.value = true;
    try {
      const result = await letmedoitTaskApi.query(queryForm);
      tableData.value = result.data.list || [];
      total.value = result.data.total || 0;
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      tableLoading.value = false;
    }
  }

  function toDetail(taskId) {
    router.push({ path: '/letmedoit/task/detail', query: { taskId } });
  }

  onMounted(queryData);
</script>

<style lang="less" scoped>
  .letmedoit-table-tip {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }

  .sub-text {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }
</style>
