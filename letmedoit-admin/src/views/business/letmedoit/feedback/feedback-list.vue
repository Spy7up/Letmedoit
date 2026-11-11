<!--
  * 让我做 · 小程序反馈
  * 数据来源：POST /appFeedback/query、/appFeedback/detail/{id}、/appFeedback/reply
  * 注意数据表是 t_app_feedback，不是框架自带的 t_feedback
-->
<template>
  <a-form class="smart-query-form">
    <a-row class="smart-query-form-row" :gutter="12">
      <a-form-item label="关键字" class="smart-query-form-item">
        <a-input style="width: 220px" v-model:value="queryForm.searchWord" placeholder="反馈内容 / 会员昵称 / 反馈ID" allow-clear @pressEnter="onSearch" />
      </a-form-item>

      <a-form-item label="类型" class="smart-query-form-item">
        <a-select style="width: 130px" v-model:value="queryForm.type" placeholder="全部类型" allow-clear>
          <a-select-option v-for="item in typeOptionList" :key="item.value" :value="item.value">{{ item.desc }}</a-select-option>
        </a-select>
      </a-form-item>

      <a-form-item label="处理状态" class="smart-query-form-item">
        <a-select style="width: 130px" v-model:value="queryForm.status" placeholder="全部状态" allow-clear>
          <a-select-option v-for="item in statusOptionList" :key="item.value" :value="item.value">{{ item.desc }}</a-select-option>
        </a-select>
      </a-form-item>

      <a-form-item label="提交时间" class="smart-query-form-item">
        <a-range-picker v-model:value="createDateRange" value-format="YYYY-MM-DD" :placeholder="['开始日期', '结束日期']" />
      </a-form-item>

      <a-form-item class="smart-query-form-item">
        <a-button-group>
          <a-button type="primary" @click="onSearch" v-privilege="'appFeedback:query'">
            <template #icon>
              <SearchOutlined />
            </template>
            查询
          </a-button>
          <a-button @click="resetQuery" v-privilege="'appFeedback:query'">
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
        <span class="letmedoit-table-tip">共 {{ total }} 条反馈 · 状态只能按 待处理→处理中→已解决→已关闭 前进，已关闭为终态</span>
      </div>
      <div class="smart-table-setting-block">
        <TableOperator v-model="columns" :tableId="TABLE_ID_CONST.BUSINESS.LETMEDOIT.FEEDBACK" :refresh="queryData" />
      </div>
    </a-row>

    <a-table
      size="small"
      :dataSource="tableData"
      :columns="columns"
      rowKey="feedbackId"
      :scroll="{ x: 1100 }"
      bordered
      :loading="tableLoading"
      :pagination="false"
      @resizeColumn="handleResizeColumn"
    >
      <template #bodyCell="{ text, record, column }">
        <template v-if="column.dataIndex === 'content'">
          <a @click="showDetail(record.feedbackId)">{{ text }}</a>
        </template>
        <template v-if="column.dataIndex === 'type'">
          <a-tag :color="typeColor(text)">{{ typeLabel(text) }}</a-tag>
        </template>
        <template v-if="column.dataIndex === 'memberNickname'">
          <a @click="toMemberDetail(record.memberId)">{{ text || '已注销用户' }}</a>
        </template>
        <template v-if="column.dataIndex === 'status'">
          <a-tag :color="statusColor(text)">{{ statusLabel(text) }}</a-tag>
        </template>
        <template v-if="column.dataIndex === 'replyEmployeeName'">
          <span v-if="text">{{ text }}</span>
          <span v-else class="sub-text">--</span>
        </template>
        <template v-if="column.dataIndex === 'action'">
          <div class="smart-table-operate">
            <a-button type="link" size="small" @click="showDetail(record.feedbackId)" v-privilege="'appFeedback:query'">
              {{ record.status === 3 ? '查看' : '处理' }}
            </a-button>
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

    <feedback-reply-drawer ref="replyDrawerRef" @reload="queryData" />
  </a-card>
</template>

<script setup>
  import { ReloadOutlined, SearchOutlined } from '@ant-design/icons-vue';
  import _ from 'lodash';
  import { onMounted, reactive, ref } from 'vue';
  import { useRouter } from 'vue-router';
  import { letmedoitFeedbackApi } from '/@/api/business/letmedoit/feedback-api';
  import TableOperator from '/@/components/support/table-operator/index.vue';
  import { PAGE_SIZE_OPTIONS } from '/@/constants/common-const';
  import {
    FEEDBACK_STATUS_COLOR,
    FEEDBACK_STATUS_ENUM,
    FEEDBACK_TYPE_COLOR,
    FEEDBACK_TYPE_ENUM,
  } from '/@/constants/business/letmedoit/feedback-const';
  import { TABLE_ID_CONST } from '/@/constants/support/table-id-const';
  import { smartSentry } from '/@/lib/smart-sentry';
  import FeedbackReplyDrawer from './components/feedback-reply-drawer.vue';

  const router = useRouter();
  const replyDrawerRef = ref();

  const typeOptionList = Object.values(FEEDBACK_TYPE_ENUM);
  const statusOptionList = Object.values(FEEDBACK_STATUS_ENUM);

  function findEnum(enumObj, value) {
    return Object.values(enumObj).find((item) => item.value === value);
  }

  const typeLabel = (value) => findEnum(FEEDBACK_TYPE_ENUM, value)?.desc || '其他';
  const typeColor = (value) => FEEDBACK_TYPE_COLOR[value] || 'default';
  const statusLabel = (value) => findEnum(FEEDBACK_STATUS_ENUM, value)?.desc || '未知';
  const statusColor = (value) => FEEDBACK_STATUS_COLOR[value] || 'default';

  const columns = ref([
    { title: '反馈内容', dataIndex: 'content', width: 300, resizable: true },
    { title: '类型', dataIndex: 'type', width: 110, resizable: true },
    { title: '提交会员', dataIndex: 'memberNickname', width: 140, resizable: true },
    { title: '状态', dataIndex: 'status', width: 100, resizable: true },
    { title: '提交时间', dataIndex: 'createTime', width: 170, resizable: true },
    { title: '处理人', dataIndex: 'replyEmployeeName', width: 120, resizable: true },
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

  const queryFormState = {
    searchWord: '',
    type: undefined,
    status: undefined,
    beginDate: undefined,
    endDate: undefined,
    pageNum: 1,
    pageSize: 10,
    sortItemList: [],
  };

  const queryForm = reactive(_.cloneDeep(queryFormState));
  const createDateRange = ref([]);
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
    queryData();
  }

  async function queryData() {
    const range = createDateRange.value || [];
    queryForm.beginDate = range[0] || undefined;
    queryForm.endDate = range[1] || undefined;

    tableLoading.value = true;
    try {
      const result = await letmedoitFeedbackApi.query(queryForm);
      tableData.value = result.data.list || [];
      total.value = result.data.total || 0;
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      tableLoading.value = false;
    }
  }

  function showDetail(feedbackId) {
    replyDrawerRef.value.show(feedbackId);
  }

  function toMemberDetail(memberId) {
    if (memberId) {
      router.push({ path: '/letmedoit/member/detail', query: { memberId } });
    }
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
