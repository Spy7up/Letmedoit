<!--
  * 让我做 · 小程序反馈处理抽屉
  * 状态流转与后端 AppFeedbackStatusEnum 一致：0→1/2/3，1→2/3，2→3，3 为终态
  * 标记「已解决」必须填写回复内容
-->
<template>
  <a-drawer v-model:open="visible" title="反馈详情与处理" :width="560" :body-style="{ paddingBottom: '72px' }" destroyOnClose>
    <a-spin :spinning="loading">
      <template v-if="detail.feedbackId">
        <a-descriptions size="small" :column="1" bordered>
          <a-descriptions-item label="反馈ID">{{ detail.feedbackId }}</a-descriptions-item>
          <a-descriptions-item label="提交会员">
            <a @click="toMemberDetail(detail.memberId)">{{ detail.memberNickname || '已注销用户' }}</a>
            <span class="sub-text">（ID {{ detail.memberId }}）</span>
          </a-descriptions-item>
          <a-descriptions-item label="类型">
            <a-tag :color="typeColor(detail.type)">{{ typeLabel(detail.type) }}</a-tag>
          </a-descriptions-item>
          <a-descriptions-item label="当前状态">
            <a-tag :color="statusColor(detail.status)">{{ statusLabel(detail.status) }}</a-tag>
          </a-descriptions-item>
          <a-descriptions-item label="提交时间">{{ detail.createTime }}</a-descriptions-item>
          <a-descriptions-item label="联系方式">{{ detail.contact || '未填写' }}</a-descriptions-item>
          <a-descriptions-item label="反馈内容">
            <div class="feedback-content">{{ detail.content }}</div>
          </a-descriptions-item>
          <a-descriptions-item label="反馈图片">
            <a-image-preview-group v-if="imageList.length > 0">
              <a-image v-for="(url, index) in imageList" :key="index" :src="url" :width="72" :height="72" />
            </a-image-preview-group>
            <span v-else class="sub-text">无</span>
          </a-descriptions-item>
          <a-descriptions-item label="上次处理">
            <template v-if="detail.replyTime">
              <div>{{ detail.replyContent }}</div>
              <div class="sub-text">{{ detail.replyEmployeeName || '未知处理人' }} · {{ detail.replyTime }}</div>
            </template>
            <span v-else class="sub-text">暂无处理记录</span>
          </a-descriptions-item>
        </a-descriptions>

        <a-divider orientation="left">处理</a-divider>

        <a-alert
          v-if="statusOptions.length === 0"
          type="success"
          show-icon
          message="该反馈已关闭，为终态，不能再流转状态。"
        />

        <a-form v-else layout="vertical">
          <a-form-item label="目标状态" required>
            <a-radio-group v-model:value="form.status">
              <a-radio-button v-for="item in statusOptions" :key="item.value" :value="item.value">
                {{ item.desc }}
              </a-radio-button>
            </a-radio-group>
          </a-form-item>
          <a-form-item :label="form.status === 2 ? '回复内容（必填）' : '回复内容（选填）'">
            <a-textarea
              v-model:value="form.replyContent"
              :rows="4"
              :maxlength="500"
              show-count
              placeholder="写清处理结论，会员可在小程序内看到"
            />
          </a-form-item>
        </a-form>
      </template>
    </a-spin>

    <template #footer>
      <a-space>
        <a-button @click="close">取消</a-button>
        <a-button
          v-if="statusOptions.length > 0"
          type="primary"
          :loading="submitting"
          @click="submit"
          v-privilege="'appFeedback:reply'"
        >
          提交处理
        </a-button>
      </a-space>
    </template>
  </a-drawer>
</template>

<script setup>
  import { message } from 'ant-design-vue';
  import { computed, reactive, ref } from 'vue';
  import { useRouter } from 'vue-router';
  import { letmedoitFeedbackApi } from '/@/api/business/letmedoit/feedback-api';
  import {
    FEEDBACK_STATUS_COLOR,
    FEEDBACK_STATUS_ENUM,
    FEEDBACK_TYPE_COLOR,
    FEEDBACK_TYPE_ENUM,
    allowNextStatusList,
  } from '/@/constants/business/letmedoit/feedback-const';
  import { smartSentry } from '/@/lib/smart-sentry';

  const emit = defineEmits(['reload']);
  const router = useRouter();

  const visible = ref(false);
  const loading = ref(false);
  const submitting = ref(false);
  const detail = ref({});
  const form = reactive({ status: undefined, replyContent: '' });

  function findEnum(enumObj, value) {
    return Object.values(enumObj).find((item) => item.value === value);
  }

  const statusLabel = (value) => findEnum(FEEDBACK_STATUS_ENUM, value)?.desc || '未知';
  const statusColor = (value) => FEEDBACK_STATUS_COLOR[value] || 'default';
  const typeLabel = (value) => findEnum(FEEDBACK_TYPE_ENUM, value)?.desc || '其他';
  const typeColor = (value) => FEEDBACK_TYPE_COLOR[value] || 'default';

  const imageList = computed(() => {
    const raw = detail.value.images;
    if (!raw) {
      return [];
    }
    try {
      const parsed = JSON.parse(raw);
      return Array.isArray(parsed) ? parsed.filter((item) => typeof item === 'string' && item.length > 0) : [];
    } catch (e) {
      return [];
    }
  });

  const statusOptions = computed(() => {
    const nextList = allowNextStatusList(detail.value.status);
    return nextList
      .map((value) => findEnum(FEEDBACK_STATUS_ENUM, value))
      .filter((item) => !!item)
      .map((item) => ({ value: item.value, desc: item.desc }));
  });

  async function load(feedbackId) {
    loading.value = true;
    try {
      const result = await letmedoitFeedbackApi.detail(feedbackId);
      detail.value = result.data || {};
      form.status = statusOptions.value.length > 0 ? statusOptions.value[0].value : undefined;
      form.replyContent = '';
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      loading.value = false;
    }
  }

  function show(feedbackId) {
    visible.value = true;
    detail.value = {};
    load(feedbackId);
  }

  function close() {
    visible.value = false;
  }

  function toMemberDetail(memberId) {
    if (!memberId) {
      return;
    }
    visible.value = false;
    router.push({ path: '/letmedoit/member/detail', query: { memberId } });
  }

  async function submit() {
    if (form.status === undefined || form.status === null) {
      message.warning('请选择目标状态');
      return;
    }
    if (form.status === 2 && !form.replyContent.trim()) {
      message.warning('标记已解决时必须填写回复内容');
      return;
    }
    submitting.value = true;
    try {
      await letmedoitFeedbackApi.reply({
        feedbackId: detail.value.feedbackId,
        status: form.status,
        replyContent: form.replyContent.trim(),
      });
      message.success('处理成功');
      visible.value = false;
      emit('reload');
    } catch (e) {
      smartSentry.captureError(e);
    } finally {
      submitting.value = false;
    }
  }

  defineExpose({ show });
</script>

<style lang="less" scoped>
  .feedback-content {
    white-space: pre-wrap;
    word-break: break-word;
  }

  .sub-text {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }
</style>
