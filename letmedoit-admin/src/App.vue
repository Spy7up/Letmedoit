<!--
  * 主应用页面
  *
  * @author letmedoit
-->

<template>
  <a-config-provider
    :locale="antdLocale"
    :theme="{
      algorithm: themeAlgorithm,
      token: {
        colorPrimary: themeColors[colorIndex].primaryColor,
        colorLink: themeColors[colorIndex].primaryColor,
        colorLinkActive: themeColors[colorIndex].activeColor,
        colorLinkHover: themeColors[colorIndex].hoverColor,
        colorIcon: themeColors[colorIndex].primaryColor,
        borderRadius: borderRadius,
      },
      components: {
        Button: {
          colorLink: themeColors[colorIndex].primaryColor,
          colorLinkActive: themeColors[colorIndex].activeColor,
          colorLinkHover: themeColors[colorIndex].hoverColor,
        },
        Icon: {
          colorIcon: themeColors[colorIndex].primaryColor,
        },
      },
    }"
    :transformCellText="transformCellText"
  >
    <!---全局loading--->
    <a-spin :spinning="spinning" tip="稍等片刻，我在拼命加载中..." size="large">
      <!--- 路由 -->
      <RouterView />
    </a-spin>
    <!-- 管理员隐藏页脚时，仍需保证 ICP 备案号可见 -->
    <div v-if="showFloatingBeian" class="floating-beian">
      <BeianInfo />
    </div>
  </a-config-provider>
</template>

<script setup>
  import dayjs from 'dayjs';
  import { computed, h, useSlots } from 'vue';
  import { messages } from '/@/i18n';
  import { useAppConfigStore } from '/@/store/modules/system/app-config';
  import { useSpinStore } from '/@/store/modules/system/spin';
  import { Popover, theme } from 'ant-design-vue';
  import { themeColors } from '/@/theme/color';
  import SmartCopyIcon from '/@/components/framework/smart-copy-icon/index.vue';
  import { useRoute } from 'vue-router';
  import BeianInfo from '/@/components/framework/beian-info/index.vue';
  import { PAGE_PATH_LOGIN } from '/@/constants/common-const';

  const route = useRoute();
  // 登录页自带备案条；非登录页在「隐藏页脚」时兜底展示备案号
  const showFloatingBeian = computed(() => useAppConfigStore().$state.footerFlag === false && route.path !== PAGE_PATH_LOGIN);

  const antdLocale = computed(() => messages[useAppConfigStore().language].antdLocale);
  const dayjsLocale = computed(() => messages[useAppConfigStore().language].dayjsLocale);
  dayjs.locale(dayjsLocale);

  // 全局loading
  let spinStore = useSpinStore();
  const spinning = computed(() => spinStore.loading);
  // 主题颜色
  const colorIndex = computed(() => {
    return useAppConfigStore().colorIndex;
  });
  // 主题
  const themeAlgorithm = computed(() => {
    let themeArray = [];
    themeArray.push(useAppConfigStore().darkModeFlag ? theme.darkAlgorithm : theme.defaultAlgorithm);
    if (useAppConfigStore().compactFlag) {
      themeArray.push(theme.compactAlgorithm);
    }
    return themeArray;
  });
  // 圆角
  const borderRadius = computed(() => {
    return useAppConfigStore().borderRadius;
  });

  function transformCellText({ text, column, record, index }) {
    if (column && column.textEllipsisFlag === true) {
      return h(
        Popover,
        { placement: 'bottom' },
        {
          default: () =>
            h(
              'div',
              {
                style: { whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' },
                id: `${column.dataIndex}${index}`,
              },
              text
            ),
          content: () =>
            h('div', { style: { display: 'flex' } }, [
              h('div', text),
              h(SmartCopyIcon, { value: document.getElementById(`${column.dataIndex}${index}`).innerText }),
            ]),
        }
      );
    } else {
      return text;
    }
  }

  const { useToken } = theme;
  const { token } = useToken();
</script>
<style lang="less">
  @color-bg-container: v-bind('token.colorBgContainer');

  :deep(.ant-table-column-sorters) {
    align-items: flex-start !important;
  }

  .smart-query-form {
    background-color: @color-bg-container;
    padding: 5px 10px;
    margin-bottom: 10px;
  }

  .smart-detail-header {
    background-color: @color-bg-container;
    padding: 10px;
  }

  // 仅在「隐藏页脚」时启用，避免备案号随页脚一起消失
  .floating-beian {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 999;
    padding: 4px 0;
    text-align: center;
    font-size: 12px;
    color: rgba(0, 0, 0, 0.45);
    background-color: rgba(255, 255, 255, 0.92);
    border-top: 1px solid rgba(0, 0, 0, 0.06);
  }
</style>
