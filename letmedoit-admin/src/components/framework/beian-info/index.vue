<!--
  * ICP 备案号：网站底部展示，点击跳转工信部备案管理系统（新窗口）
  *
  * @author letmedoit
-->
<template>
  <a class="beian-info" :href="ICP_BEIAN.url" target="_blank" rel="noopener noreferrer">{{ ICP_BEIAN.number }}</a>
</template>
<script setup>
  import { ICP_BEIAN } from '/@/constants/site-const';
</script>
<style lang="less" scoped>
  .beian-info {
    color: inherit;
    text-decoration: none;
    &:hover {
      text-decoration: underline;
    }
  }
</style>
