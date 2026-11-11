<!--
  * 让我做 · 任务详情
  * 数据来源：GET /task/detail/{taskId}
  * 只读：展示任务档案、参与者完成情况、事件时间线
-->
<template>
  <a-spin :spinning="loading">
    <div class="smart-detail-header">
      <a-page-header :title="detail.title || '任务详情'" :sub-title="`#${detail.taskId || '-'}`">
        <template #extra>
          <a-space>
            <a-tag :color="statusColor(detail.status)">{{ statusLabel(detail.status) }}</a-tag>
            <a-tag v-if="detail.overdueFlag" color="red">已逾期</a-tag>
            <a-button @click="backToList">
              <template #icon>
                <RollbackOutlined />
              </template>
              返回任务列表
            </a-button>
          </a-space>
        </template>
        <a-descriptions size="small" :column="3">
          <a-descriptions-item label="委托人">
            <a @click="toMemberDetail(detail.creatorId)">{{ detail.creatorNickname || '已注销用户' }}</a>
          </a-descriptions-item>
          <a-descriptions-item label="完成条件">{{ completionModeLabel(detail.completionMode) }}</a-descriptions-item>
          <a-descriptions-item label="开始时间">{{ detail.startTime || '立即生效' }}</a-descriptions-item>
          <a-descriptions-item label="截止时间">{{ detail.deadline || '--' }}</a-descriptions-item>
          <a-descriptions-item label="提前提醒">{{ detail.remindMinutes ? `${detail.remindMinutes} 分钟` : '不提醒' }}</a-descriptions-item>
          <a-descriptions-item label="编辑次数">{{ detail.editCount ?? 0 }}</a-descriptions-item>
          <a-descriptions-item label="参与者">
            已接受 {{ detail.acceptedCount ?? 0 }} / 共 {{ detail.participantCount ?? 0 }}
          </a-descriptions-item>
          <a-descriptions-item label="已完成">{{ detail.completedCount ?? 0 }}</a-descriptions-item>
          <a-descriptions-item label="创建时间">{{ detail.createTime || '--' }}</a-descriptions-item>
        </a-descriptions>
      </a-page-header>
    </div>

    <a-card size="small" :bordered="false" title="交代内容">
      <p class="task-desc">{{ detail.description || '没有填写交代内容' }}</p>
      <a-space v-if="imageList.length > 0" :size="8" wrap>
        <a-image-preview-group>
          <a-image v-for="(url, index) in imageList" :key="index" :src="url" :width="96" :height="96" class="task-image" />
        </a-image-preview-group>
      </a-space>
    </a-card>

    <a-card size="small" :bordered="false" class="smart-margin-top10" title="参与者与完成情况">
      <a-table
        size="small"
        :dataSource="participantList"
        :columns="participantColumns"
        rowKey="participantId"
        :pagination="false"
        :locale="{ emptyText: '还没有参与者' }"
      >
        <template #bodyCell="{ text, record, column }">
          <template v-if="column.dataIndex === 'nickname'">
            <a-space>
              <a-avatar :size="24" :src="record.avatar || undefined">
                {{ (text || '会').slice(0, 1) }}
              </a-avatar>
              <a @click="toMemberDetail(record.memberId)">{{ text || '已注销用户' }}</a>
            </a-space>
          </template>
          <template v-if="column.dataIndex === 'status'">
            <a-tag :color="participantStatusColor(text)">{{ participantStatusLabel(text) }}</a-tag>
          </template>
          <template v-if="column.dataIndex === 'onTimeFlag'">
            <span v-if="text === null || text === undefined" class="sub-text">--</span>
            <a-tag v-else :color="text ? 'green' : 'red'">{{ text ? '准时' : '逾期' }}</a-tag>
          </template>
          <template v-if="column.dataIndex === 'proof'">
            <a-image-preview-group v-if="parseImages(record.completeImages).length > 0">
              <a-image
                v-for="(url, index) in parseImages(record.completeImages)"
                :key="index"
                :src="url"
                :width="40"
                :height="40"
              />
            </a-image-preview-group>
            <span v-else class="sub-text">--</span>
          </template>
        </template>
      </a-table>
    </a-card>

    <a-card size="small" :bordered="false" class="smart-margin-top10" title="事件时间线">
      <a-timeline v-if="eventList.length > 0">
        <a-timeline-item v-for="item in eventList" :key="item.eventId" :color="eventColor(item.eventType)">
          <div class="event-title">
            {{ eventLabel(item.eventType) }}
            <span class="sub-text">· {{ item.actorNickname || '系统' }}</span>
          </div>
          <div class="event-content">{{ item.content }}</div>
          <div class="sub-text">{{ item.createTime }}</div>
        </a-timeline-item>
      </a-timeline>
      <a-empty v-else description="暂无事件记录" />
    </a-card>
  </a-spin>
</template>

<script setup>
  import { RollbackOutlined } from '@ant-design/icons-vue';
  import { computed, onMounted, ref, watch } from 'vue';
  import { useRoute, useRouter } from 'vue-router';
  import { letmedoitTaskApi } from '/@/api/business/letmedoit/task-api';
  import {
    TASK_COMPLETION_MODE_ENUM,
    TASK_EVENT_TYPE_ENUM,
    TASK_PARTICIPANT_STATUS_ENUM,
    TASK_STATUS_COLOR,
    TASK_STATUS_ENUM,
  } from '/@/constants/business/letmedoit/task-const';
  import { smartSentry } from '/@/lib/smart-sentry';

  const route = useRoute();
  const router = useRouter();

  const loading = ref(false);
  const taskId = ref(null);
  const detail = ref({});

  function findDesc(enumObj, value) {
    const target = Object.values(enumObj).find((item) => item.value === value);
    return target ? target.desc : null;
  }

  function statusLabel(status) {
    return findDesc(TASK_STATUS_ENUM, status) || '未知状态';
  }

  function statusColor(status) {
    return TASK_STATUS_COLOR[status] || 'default';
  }

  function completionModeLabel(value) {
    return findDesc(TASK_COMPLETION_MODE_ENUM, value) || '--';
  }

  function participantStatusLabel(value) {
    return findDesc(TASK_PARTICIPANT_STATUS_ENUM, value) || '--';
  }

  function participantStatusColor(value) {
    return { 0: 'gold', 1: 'processing', 2: 'green', 3: 'red', 4: 'default' }[value] || 'default';
  }

  function eventLabel(value) {
    return findDesc(TASK_EVENT_TYPE_ENUM, value) || '事件';
  }

  function eventColor(value) {
    return { 5: 'green', 4: 'red', 6: 'gray', 7: 'orange' }[value] || 'blue';
  }

  const participantColumns = [
    { title: '参与者', dataIndex: 'nickname', ellipsis: true },
    { title: '参与状态', dataIndex: 'status', width: 110 },
    { title: '完成时间', dataIndex: 'completeTime', width: 170 },
    { title: '是否准时', dataIndex: 'onTimeFlag', width: 100 },
    { title: '完成备注', dataIndex: 'completeRemark', ellipsis: true },
    { title: '凭证', dataIndex: 'proof', width: 130 },
    { title: '拒绝理由', dataIndex: 'rejectReason', ellipsis: true, width: 160 },
  ];

  const participantList = computed(() => detail.value.participantList || []);
  const eventList = computed(() => detail.value.eventList || []);

  function parseImages(raw) {
    if (!raw) {
      return [];
    }
    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed.filter((item) => typeof item === 'string' && item.length > 0) : [];
    } catch (e) {
      return [];
    }
  }

  const imageList = computed(() => parseImages(detail.value.images));

  function backToList() {
    router.push({ path: '/letmedoit/task' });
  }

  function toMemberDetail(memberId) {
    if (memberId) {
      router.push({ path: '/letmedoit/member/detail', query: { memberId } });
    }
  }

  async function loadDetail() {
    if (!taskId.value) {
      return;
    }
    loading.value = true;
    try {
      const result = await letmedoitTaskApi.detail(taskId.value);
      detail.value = result.data || {};
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      loading.value = false;
    }
  }

  function readTaskId() {
    const queryTaskId = route.query.taskId;
    taskId.value = queryTaskId ? Number(queryTaskId) : null;
  }

  watch(
    () => route.query.taskId,
    () => {
      readTaskId();
      loadDetail();
    }
  );

  onMounted(() => {
    readTaskId();
    loadDetail();
  });
</script>

<style lang="less" scoped>
  .task-desc {
    margin-bottom: 12px;
    color: rgba(0, 0, 0, 0.75);
    white-space: pre-wrap;
    word-break: break-word;
  }

  .task-image {
    object-fit: cover;
    border-radius: 4px;
  }

  .event-title {
    color: rgba(0, 0, 0, 0.85);
    font-weight: 500;
  }

  .event-content {
    color: rgba(0, 0, 0, 0.65);
    word-break: break-word;
  }

  .sub-text {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }
</style>
