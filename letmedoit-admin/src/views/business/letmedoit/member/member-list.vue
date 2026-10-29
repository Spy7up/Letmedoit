<!--
  * 让我做 · 会员管理
  * 数据来源：POST /member/query
  * 指标口径见 doc/design/管理后台开发技术规范.md §3.4
-->
<template>
  <!---------- 查询表单 begin ----------->
  <a-form class="smart-query-form">
    <a-row class="smart-query-form-row" :gutter="12">
      <a-form-item label="关键字" class="smart-query-form-item">
        <a-input
          style="width: 220px"
          v-model:value="queryForm.searchWord"
          placeholder="昵称 / 邀请码 / 会员ID"
          allow-clear
          @pressEnter="onSearch"
        />
      </a-form-item>

      <a-form-item label="会员状态" class="smart-query-form-item">
        <a-select style="width: 130px" v-model:value="queryForm.disabledFlag" placeholder="全部状态" allow-clear>
          <a-select-option :value="false">正常</a-select-option>
          <a-select-option :value="true">已禁用</a-select-option>
        </a-select>
      </a-form-item>

      <a-form-item label="注册时间" class="smart-query-form-item">
        <a-range-picker v-model:value="registerDateRange" value-format="YYYY-MM-DD" :placeholder="['开始日期', '结束日期']" />
      </a-form-item>

      <a-form-item class="smart-query-form-item">
        <a-button-group>
          <a-button type="primary" @click="onSearch" v-privilege="'member:query'">
            <template #icon>
              <SearchOutlined />
            </template>
            查询
          </a-button>
          <a-button @click="resetQuery" v-privilege="'member:query'">
            <template #icon>
              <ReloadOutlined />
            </template>
            重置
          </a-button>
        </a-button-group>
      </a-form-item>
    </a-row>
  </a-form>
  <!---------- 查询表单 end ----------->

  <a-card size="small" :bordered="false" :hoverable="true">
    <a-row class="smart-table-btn-block">
      <div class="smart-table-operate-block">
        <span class="letmedoit-table-tip">准时率 = 准时完成样本 / 完成样本，零样本显示 --</span>
      </div>
      <div class="smart-table-setting-block">
        <TableOperator v-model="columns" :tableId="TABLE_ID_CONST.BUSINESS.LETMEDOIT.MEMBER" :refresh="queryData" />
      </div>
    </a-row>

    <a-table
      size="small"
      :dataSource="tableData"
      :columns="columns"
      rowKey="memberId"
      :scroll="{ x: 1180 }"
      bordered
      :loading="tableLoading"
      :pagination="false"
      :showSorterTooltip="false"
      @resizeColumn="handleResizeColumn"
    >
      <template #bodyCell="{ text, record, column }">
        <template v-if="column.dataIndex === 'nickname'">
          <a-space>
            <a-avatar :size="26" :src="record.avatar || undefined">
              {{ (text || '会').slice(0, 1) }}
            </a-avatar>
            <a @click="toDetail(record.memberId)">{{ text || '未设置昵称' }}</a>
            <a-tag v-if="record.disabledFlag" color="red">已禁用</a-tag>
          </a-space>
        </template>
        <template v-if="column.dataIndex === 'onTimeRate'">
          <span :class="rateClass(text)">{{ formatRate(text) }}</span>
        </template>
        <template v-if="column.dataIndex === 'action'">
          <div class="smart-table-operate">
            <a-button type="link" size="small" @click="toDetail(record.memberId)" v-privilege="'member:query'">
              报表详情
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
  </a-card>
</template>

<script setup>
  import { ReloadOutlined, SearchOutlined } from '@ant-design/icons-vue';
  import _ from 'lodash';
  import { onMounted, reactive, ref } from 'vue';
  import { useRouter } from 'vue-router';
  import { letmedoitMemberApi } from '/@/api/business/letmedoit/member-api';
  import TableOperator from '/@/components/support/table-operator/index.vue';
  import { PAGE_SIZE_OPTIONS } from '/@/constants/common-const';
  import { TABLE_ID_CONST } from '/@/constants/support/table-id-const';
  import { smartSentry } from '/@/lib/smart-sentry';

  const router = useRouter();

  // ---------------------------- 表格列 ----------------------------
  const columns = ref([
    { title: '会员', dataIndex: 'nickname', width: 200, resizable: true },
    { title: '会员ID', dataIndex: 'memberId', width: 100, resizable: true },
    { title: '邀请码', dataIndex: 'inviteCode', width: 100, resizable: true },
    { title: '帮手数', dataIndex: 'helperCount', width: 90, resizable: true },
    { title: '发起任务', dataIndex: 'createdTaskCount', width: 100, resizable: true },
    { title: '参与任务', dataIndex: 'participantCount', width: 100, resizable: true },
    { title: '完成样本', dataIndex: 'completedCount', width: 100, resizable: true },
    { title: '准时率', dataIndex: 'onTimeRate', width: 100, resizable: true },
    { title: '注册时间', dataIndex: 'createTime', width: 170, resizable: true },
    { title: '最近登录', dataIndex: 'lastLoginTime', width: 170, resizable: true },
    { title: '操作', dataIndex: 'action', width: 110, fixed: 'right', resizable: true },
  ]);

  function handleResizeColumn(w, col) {
    columns.value.forEach((item) => {
      if (item.dataIndex === col.dataIndex) {
        item.width = Math.floor(w);
        item.dragAndDropFlag = true;
      }
    });
  }

  // ---------------------------- 查询 ----------------------------
  const queryFormState = {
    searchWord: '',
    disabledFlag: undefined,
    beginDate: undefined,
    endDate: undefined,
    pageNum: 1,
    pageSize: 10,
    sortItemList: [],
  };

  const queryForm = reactive(_.cloneDeep(queryFormState));
  const registerDateRange = ref([]);
  const tableLoading = ref(false);
  const tableData = ref([]);
  const total = ref(0);

  function formatRate(value) {
    if (value === null || value === undefined) {
      return '--';
    }
    return `${Number(value).toFixed(1)}%`;
  }

  function rateClass(value) {
    if (value === null || value === undefined) {
      return 'rate-empty';
    }
    const rate = Number(value);
    if (rate >= 90) {
      return 'rate-good';
    }
    if (rate >= 70) {
      return 'rate-normal';
    }
    return 'rate-bad';
  }

  function syncDateRange() {
    const range = registerDateRange.value || [];
    queryForm.beginDate = range[0] || undefined;
    queryForm.endDate = range[1] || undefined;
  }

  function onSearch() {
    queryForm.pageNum = 1;
    queryData();
  }

  function resetQuery() {
    const pageSize = queryForm.pageSize;
    Object.assign(queryForm, _.cloneDeep(queryFormState));
    queryForm.pageSize = pageSize;
    registerDateRange.value = [];
    queryData();
  }

  async function queryData() {
    syncDateRange();
    tableLoading.value = true;
    try {
      const result = await letmedoitMemberApi.query(queryForm);
      tableData.value = result.data.list || [];
      total.value = result.data.total || 0;
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      tableLoading.value = false;
    }
  }

  function toDetail(memberId) {
    router.push({ path: '/letmedoit/member/detail', query: { memberId } });
  }

  onMounted(queryData);
</script>

<style lang="less" scoped>
  .letmedoit-table-tip {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }

  .rate-good {
    color: #389e0d;
    font-weight: 600;
  }

  .rate-normal {
    color: #d48806;
    font-weight: 600;
  }

  .rate-bad {
    color: #cf1322;
    font-weight: 600;
  }

  .rate-empty {
    color: rgba(0, 0, 0, 0.25);
  }
</style>
