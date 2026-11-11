<!-- 让我做 · 小程序版本管理 -->
<template>
  <a-form class="smart-query-form">
    <a-row class="smart-query-form-row" :gutter="12">
      <a-form-item label="版本号" class="smart-query-form-item">
        <a-input style="width: 180px" v-model:value="queryForm.version" placeholder="请输入版本号" allow-clear @pressEnter="onSearch" />
      </a-form-item>

      <a-form-item label="发布状态" class="smart-query-form-item">
        <a-select style="width: 140px" v-model:value="queryForm.currentFlag" placeholder="全部状态" allow-clear>
          <a-select-option :value="true">当前版本</a-select-option>
          <a-select-option :value="false">非当前版本</a-select-option>
        </a-select>
      </a-form-item>

      <a-form-item label="发布时间" class="smart-query-form-item">
        <a-range-picker v-model:value="releaseDateRange" value-format="YYYY-MM-DD" :placeholder="['开始日期', '结束日期']" />
      </a-form-item>

      <a-form-item class="smart-query-form-item">
        <a-button-group>
          <a-button type="primary" @click="onSearch" v-privilege="'appVersion:query'">
            <template #icon><SearchOutlined /></template>
            查询
          </a-button>
          <a-button @click="resetQuery" v-privilege="'appVersion:query'">
            <template #icon><ReloadOutlined /></template>
            重置
          </a-button>
        </a-button-group>
        <a-button type="primary" class="smart-margin-left20" @click="showForm()" v-privilege="'appVersion:add'">
          <template #icon><PlusOutlined /></template>
          新增版本
        </a-button>
      </a-form-item>
    </a-row>
  </a-form>

  <a-card size="small" :bordered="false" :hoverable="true">
    <a-row class="smart-table-btn-block">
      <div class="smart-table-operate-block">
        <span class="version-table-tip">共 {{ total }} 个版本 · 请先发布小程序包，再发布对应版本记录</span>
      </div>
      <div class="smart-table-setting-block">
        <TableOperator v-model="columns" :tableId="TABLE_ID_CONST.BUSINESS.LETMEDOIT.VERSION" :refresh="queryData" />
      </div>
    </a-row>

    <a-table
      size="small"
      :dataSource="tableData"
      :columns="columns"
      rowKey="versionId"
      :scroll="{ x: 1500 }"
      bordered
      :loading="tableLoading"
      :pagination="false"
      @resizeColumn="handleResizeColumn"
    >
      <template #bodyCell="{ text, record, column }">
        <template v-if="column.dataIndex === 'version'">
          <span class="version-number">{{ text }}</span>
        </template>
        <template v-if="column.dataIndex === 'versionLabel'">
          {{ text || `v${record.version}` }}
        </template>
        <template v-if="column.dataIndex === 'appType'">
          {{ text === 'miniapp' ? '微信小程序' : text }}
        </template>
        <template v-if="column.dataIndex === 'currentFlag'">
          <a-tag :color="versionStatus(record).color">{{ versionStatus(record).label }}</a-tag>
        </template>
        <template v-if="column.dataIndex === 'releaseNote'">
          <a-tooltip :title="text">
            <span>{{ text || '--' }}</span>
          </a-tooltip>
        </template>
        <template v-if="column.dataIndex === 'releaseTime' || column.dataIndex === 'minBaseLib'">
          {{ text || '--' }}
        </template>
        <template v-if="column.dataIndex === 'forceUpdateFlag'">
          <a-tag :color="text ? 'red' : 'default'">{{ text ? '是' : '否' }}</a-tag>
        </template>
        <template v-if="column.dataIndex === 'action'">
          <div class="smart-table-operate">
            <a-button type="link" size="small" @click="showForm(record)" v-privilege="'appVersion:update'">编辑</a-button>
            <a-button
              v-if="!record.currentFlag"
              type="link"
              size="small"
              :loading="publishLoadingId === record.versionId"
              @click="onPublish(record)"
              v-privilege="'appVersion:publish'"
            >
              发布
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

    <version-form-modal ref="formModalRef" @reloadList="queryData" />
  </a-card>
</template>

<script setup>
  import { PlusOutlined, ReloadOutlined, SearchOutlined } from '@ant-design/icons-vue';
  import { Modal, message } from 'ant-design-vue';
  import _ from 'lodash';
  import { onMounted, reactive, ref } from 'vue';
  import { letmedoitVersionApi } from '/@/api/business/letmedoit/version-api';
  import TableOperator from '/@/components/support/table-operator/index.vue';
  import { PAGE_SIZE_OPTIONS } from '/@/constants/common-const';
  import { TABLE_ID_CONST } from '/@/constants/support/table-id-const';
  import { smartSentry } from '/@/lib/smart-sentry';
  import VersionFormModal from './components/version-form-modal.vue';

  const formModalRef = ref();
  const publishLoadingId = ref();

  const columns = ref([
    { title: '版本号', dataIndex: 'version', width: 120, resizable: true },
    { title: '展示版本', dataIndex: 'versionLabel', width: 140, resizable: true },
    { title: '端类型', dataIndex: 'appType', width: 120, resizable: true },
    { title: '发布状态', dataIndex: 'currentFlag', width: 110, resizable: true },
    { title: '更新说明', dataIndex: 'releaseNote', width: 260, ellipsis: true, resizable: true },
    { title: '发布时间', dataIndex: 'releaseTime', width: 170, resizable: true },
    { title: '最低基础库', dataIndex: 'minBaseLib', width: 120, resizable: true },
    { title: '强制更新', dataIndex: 'forceUpdateFlag', width: 100, resizable: true },
    { title: '更新时间', dataIndex: 'updateTime', width: 170, resizable: true },
    { title: '操作', dataIndex: 'action', width: 140, fixed: 'right', resizable: true },
  ]);

  const queryFormState = {
    version: '',
    currentFlag: undefined,
    beginDate: undefined,
    endDate: undefined,
    pageNum: 1,
    pageSize: 10,
    sortItemList: [],
  };
  const queryForm = reactive(_.cloneDeep(queryFormState));
  const releaseDateRange = ref([]);
  const tableLoading = ref(false);
  const tableData = ref([]);
  const total = ref(0);

  function versionStatus(record) {
    if (record.currentFlag) {
      return { label: '当前版本', color: 'blue' };
    }
    return record.releaseTime ? { label: '非当前版本', color: 'default' } : { label: '待发布', color: 'orange' };
  }

  function handleResizeColumn(width, column) {
    const target = columns.value.find((item) => item.dataIndex === column.dataIndex);
    if (target) {
      target.width = Math.floor(width);
      target.dragAndDropFlag = true;
    }
  }

  function onSearch() {
    queryForm.pageNum = 1;
    queryData();
  }

  function resetQuery() {
    const pageSize = queryForm.pageSize;
    Object.assign(queryForm, _.cloneDeep(queryFormState));
    queryForm.pageSize = pageSize;
    releaseDateRange.value = [];
    queryData();
  }

  async function queryData() {
    const range = releaseDateRange.value || [];
    queryForm.beginDate = range[0] || undefined;
    queryForm.endDate = range[1] || undefined;
    tableLoading.value = true;
    try {
      const result = await letmedoitVersionApi.query(queryForm);
      tableData.value = result.data.list || [];
      total.value = result.data.total || 0;
    } catch (error) {
      smartSentry.captureError(error);
    } finally {
      tableLoading.value = false;
    }
  }

  function showForm(record) {
    formModalRef.value.showModal(record);
  }

  function onPublish(record) {
    Modal.confirm({
      title: `发布版本 ${record.versionLabel || `v${record.version}`}`,
      content: '请确认对应小程序包已经发布。发布后，该记录将成为当前对外版本，原当前版本自动下线。',
      okText: '确认发布',
      cancelText: '取消',
      async onOk() {
        publishLoadingId.value = record.versionId;
        try {
          await letmedoitVersionApi.publish({ versionId: record.versionId });
          message.success('版本发布成功');
          await queryData();
        } catch (error) {
          smartSentry.captureError(error);
        } finally {
          publishLoadingId.value = undefined;
        }
      },
    });
  }

  onMounted(queryData);
</script>

<style lang="less" scoped>
  .version-table-tip {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }

  .version-number {
    color: #1677ff;
    font-weight: 600;
  }
</style>
