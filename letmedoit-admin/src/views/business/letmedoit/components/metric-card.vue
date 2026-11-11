<!--
  * 让我做 · 指标卡
  * 用于概览与会员详情：label 说明口径，value 主数值，tip 辅助说明
-->
<template>
  <div class="metric-card">
    <div class="metric-label">
      {{ label }}
      <a-tooltip v-if="tip" :title="tip">
        <QuestionCircleOutlined class="metric-tip-icon" />
      </a-tooltip>
    </div>
    <div class="metric-value" :class="{ 'metric-empty': isEmpty }">{{ displayValue }}</div>
    <div v-if="sub" class="metric-sub">{{ sub }}</div>
  </div>
</template>

<script setup>
  import { QuestionCircleOutlined } from '@ant-design/icons-vue';
  import { computed } from 'vue';

  const props = defineProps({
    label: {
      type: String,
      default: '',
    },
    value: {
      type: [Number, String],
      default: null,
    },
    suffix: {
      type: String,
      default: '',
    },
    sub: {
      type: String,
      default: '',
    },
    tip: {
      type: String,
      default: '',
    },
  });

  const isEmpty = computed(() => props.value === null || props.value === undefined || props.value === '');
  const displayValue = computed(() => {
    if (isEmpty.value) {
      return '--';
    }
    return `${props.value}${props.suffix}`;
  });
</script>

<style lang="less" scoped>
  .metric-card {
    height: 100%;
    padding: 14px 16px;
    background: #fff;
    border: 1px solid #edf0f5;
    border-left: 3px solid @primary-color;
    border-radius: 6px;
    box-shadow: 0 1px 2px rgba(31, 35, 41, 0.02);
  }

  .metric-label {
    color: rgba(0, 0, 0, 0.55);
    font-size: 13px;
  }

  .metric-tip-icon {
    margin-left: 4px;
    color: rgba(0, 0, 0, 0.35);
    cursor: help;
  }

  .metric-value {
    margin: 6px 0 2px;
    font-size: 26px;
    font-weight: 600;
    line-height: 1.3;
    color: rgba(0, 0, 0, 0.85);
  }

  .metric-empty {
    color: rgba(0, 0, 0, 0.25);
  }

  .metric-sub {
    color: rgba(0, 0, 0, 0.45);
    font-size: 12px;
  }
</style>
