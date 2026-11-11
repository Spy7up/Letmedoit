<!--
  * 让我做 · 帮手关系
  * 数据来源：POST /helper/query
  * 关系是双向双写（A→B、B→A 各一行），这里按行展示，不做去重
-->
<template>
  <a-form class="smart-query-form">
    <a-row class="smart-query-form-row" :gutter="12">
      <a-form-item label="关键字" class="smart-query-form-item">
        <a-input style="width: 220px" v-model:value="queryForm.searchWord" placeholder="双方昵称 / 邀请码" allow-clear @pressEnter="onSearch" />
      </a-form-item>

      <a-form-item label="建立时间" class="smart-query-form-item">
        <a-range-picker v-model:value="createDateRange" value-format="YYYY-MM-DD" :placeholder="['开始日期', '结束日期']" />
      </a-form-item>

      <a-form-item class="smart-query-form-item">
        <a-button-group>
          <a-button type="primary" @click="onSearch" v-privilege="'helper:query'">
            <template #icon>
              <SearchOutlined />
            </template>
            查询
          </a-button>
          <a-button @click="resetQuery" v-privilege="'helper:query'">
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
    <a-alert
      type="info"
      show-icon
      class="smart-margin-bottom10"
      message="关系按双向双写记录展示，全站好友对统计按双方 ID 去重计算，两者数值不同属正常现象。"
    />

    <a-row class="smart-table-btn-block">
      <div class="smart-table-operate-block">
        <span class="letmedoit-table-tip">共 {{ total }} 条关系记录（含双向）</span>
      </div>
      <div class="smart-table-setting-block">
        <TableOperator v-model="columns" :tableId="TABLE_ID_CONST.BUSINESS.LETMEDOIT.HELPER" :refresh="queryData" />
      </div>
    </a-row>

    <a-table
      size="small"
      :dataSource="tableData"
      :columns="columns"
      rowKey="helperId"
      :scroll="{ x: 1000 }"
      bordered
      :loading="tableLoading"
      :pagination="false"
      @resizeColumn="handleResizeColumn"
    >
      <template #bodyCell="{ text, record, column }">
        <template v-if="column.dataIndex === 'memberNickname'">
          <a @click="toMemberDetail(record.memberId)">{{ text || '已注销用户' }}</a>
          <div class="sub-text">{{ record.memberInviteCode || '--' }}</div>
        </template>
        <template v-if="column.dataIndex === 'helperNickname'">
          <a @click="toMemberDetail(record.helperMemberId)">{{ text || '已注销用户' }}</a>
          <div class="sub-text">{{ record.helperInviteCode || '--' }}</div>
        </template>
        <template v-if="column.dataIndex === 'action'">
          <div class="smart-table-operate">
            <a-button type="link" size="small" @click="toMemberDetail(record.memberId)">会员报表</a-button>
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
  import { letmedoitHelperApi } from '/@/api/business/letmedoit/helper-api';
  import TableOperator from '/@/components/support/table-operator/index.vue';
  import { PAGE_SIZE_OPTIONS } from '/@/constants/common-const';
  import { TABLE_ID_CONST } from '/@/constants/support/table-id-const';
  import { smartSentry } from '/@/lib/smart-sentry';

  const router = useRouter();

  const columns = ref([
    { title: '会员', dataIndex: 'memberNickname', width: 200, resizable: true },
    { title: '帮手', dataIndex: 'helperNickname', width: 200, resizable: true },
    { title: '备注名', dataIndex: 'remark', width: 160, resizable: true },
    { title: '建立时间', dataIndex: 'createTime', width: 180, resizable: true },
    { title: '操作', dataIndex: 'action', width: 120, fixed: 'right', resizable: true },
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
      const result = await letmedoitHelperApi.query(queryForm);
      tableData.value = result.data.list || [];
      total.value = result.data.total || 0;
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      tableLoading.value = false;
    }
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
