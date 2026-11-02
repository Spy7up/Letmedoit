<!--
  * 底部：版权、公司等信息
  *
  * @author letmedoit
-->
<template>
  <div class="version">
    <span class="smart-copyright">©{{ currentYear }} 让我做 · 运营管理后台</span>
  </div>
</template>
<script setup>
  import dayjs from 'dayjs';

  const currentYear = dayjs().year();
</script>

<style lang="less" scoped>
  .version {
    font-size: 14px;
    color: rgba(0, 0, 0, 0.45);
    a {
      color: rgba(0, 0, 0, 0.45);
    }
    a:hover {
      color: @primary-color;
    }
  }
</style>
