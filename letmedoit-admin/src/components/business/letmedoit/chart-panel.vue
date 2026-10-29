<!--
  * ECharts 容器：统一处理初始化、响应式 resize、卸载 dispose
  * 业务页面只负责传 option，不直接碰 echarts 实例
-->
<template>
  <div ref="chartRef" class="letmedoit-chart" :style="{ height: height }"></div>
</template>

<script setup>
  import * as echarts from 'echarts';
  import { nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue';

  const props = defineProps({
    option: {
      type: Object,
      default: () => ({}),
    },
    height: {
      type: String,
      default: '280px',
    },
  });

  const chartRef = ref();
  let chart = null;

  function resize() {
    if (chart) {
      chart.resize();
    }
  }

  function render() {
    if (!chartRef.value) {
      return;
    }
    if (!chart) {
      chart = echarts.init(chartRef.value);
    }
    chart.setOption(props.option || {}, true);
  }

  watch(
    () => props.option,
    () => {
      nextTick(render);
    },
    { deep: true }
  );

  onMounted(() => {
    nextTick(render);
    window.addEventListener('resize', resize);
  });

  onBeforeUnmount(() => {
    window.removeEventListener('resize', resize);
    if (chart) {
      chart.dispose();
      chart = null;
    }
  });
</script>

<style lang="less" scoped>
  .letmedoit-chart {
    width: 100%;
  }
</style>
