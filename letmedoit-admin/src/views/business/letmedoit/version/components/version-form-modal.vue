<template>
  <a-modal
    :open="visible"
    :title="isEdit ? '编辑版本' : '新增版本'"
    :width="640"
    :confirm-loading="submitLoading"
    :mask-closable="false"
    ok-text="保存"
    cancel-text="取消"
    @ok="onSubmit"
    @cancel="onClose"
  >
    <a-alert v-if="!isEdit" type="info" show-icon message="保存仅新增版本记录，不会自动对外发布。" class="form-tip" />
    <a-form ref="formRef" :model="form" :rules="rules" :label-col="{ span: 5 }" :wrapper-col="{ span: 17 }">
      <a-form-item label="端类型" name="appType">
        <a-select v-model:value="form.appType" :disabled="isEdit" placeholder="请选择端类型">
          <a-select-option value="miniapp">微信小程序</a-select-option>
        </a-select>
      </a-form-item>

      <a-form-item label="版本号" name="version" extra="格式为 x.y.z；创建后不可修改，历史版本请保留。">
        <a-input v-model:value="form.version" :disabled="isEdit" :maxlength="32" placeholder="例如 1.1.0" />
      </a-form-item>

      <a-form-item label="展示版本" name="versionLabel">
        <a-input v-model:value="form.versionLabel" :maxlength="32" placeholder="留空则显示 v + 版本号" />
      </a-form-item>

      <a-form-item label="更新说明" name="releaseNote">
        <a-textarea
          v-model:value="form.releaseNote"
          :rows="4"
          :maxlength="500"
          show-count
          placeholder="请输入本次更新内容，将展示在小程序「关于」弹窗中"
        />
      </a-form-item>

      <a-form-item label="发布时间" name="releaseTime" extra="可留空，发布时自动填写实际操作时间。">
        <a-date-picker
          style="width: 100%"
          v-model:value="form.releaseTime"
          show-time
          format="YYYY-MM-DD HH:mm:ss"
          value-format="YYYY-MM-DD HH:mm:ss"
          placeholder="请选择发布时间"
        />
      </a-form-item>

      <a-form-item label="最低基础库" name="minBaseLib">
        <a-input v-model:value="form.minBaseLib" :maxlength="16" placeholder="例如 2.32.3（预留字段）" />
      </a-form-item>

      <a-form-item label="强制更新" name="forceUpdateFlag" extra="当前为预留字段，小程序暂未执行强制更新。">
        <a-switch v-model:checked="form.forceUpdateFlag" checked-children="是" un-checked-children="否" />
      </a-form-item>
    </a-form>
  </a-modal>
</template>

<script setup>
  import { message } from 'ant-design-vue';
  import { computed, nextTick, reactive, ref } from 'vue';
  import { letmedoitVersionApi } from '/@/api/business/letmedoit/version-api';
  import { smartSentry } from '/@/lib/smart-sentry';

  const emit = defineEmits(['reloadList']);
  const formRef = ref();
  const visible = ref(false);
  const submitLoading = ref(false);

  const formDefault = {
    versionId: undefined,
    appType: 'miniapp',
    version: '',
    versionLabel: '',
    releaseNote: '',
    releaseTime: undefined,
    minBaseLib: '',
    forceUpdateFlag: false,
  };
  const form = reactive({ ...formDefault });
  const isEdit = computed(() => Boolean(form.versionId));

  const rules = {
    appType: [{ required: true, message: '请选择端类型', trigger: 'change' }],
    version: [
      { required: true, message: '请输入版本号', trigger: 'blur' },
      { pattern: /^\d+\.\d+\.\d+$/, message: '版本号格式应为 x.y.z，例如 1.1.0', trigger: 'blur' },
    ],
  };

  async function showModal(rowData) {
    Object.assign(form, formDefault);
    if (rowData) {
      Object.keys(formDefault).forEach((key) => {
        form[key] = rowData[key] ?? formDefault[key];
      });
    }
    visible.value = true;
    await nextTick();
    formRef.value?.clearValidate();
  }

  function onClose() {
    visible.value = false;
    Object.assign(form, formDefault);
  }

  async function onSubmit() {
    try {
      await formRef.value.validate();
    } catch (error) {
      return;
    }

    const payload = {
      versionId: form.versionId,
      appType: form.appType,
      version: form.version?.trim(),
      versionLabel: form.versionLabel?.trim() || null,
      releaseNote: form.releaseNote?.trim() || null,
      releaseTime: form.releaseTime || null,
      minBaseLib: form.minBaseLib?.trim() || null,
      forceUpdateFlag: form.forceUpdateFlag,
    };

    submitLoading.value = true;
    try {
      if (isEdit.value) {
        await letmedoitVersionApi.update(payload);
      } else {
        await letmedoitVersionApi.add(payload);
      }
      message.success(isEdit.value ? '版本修改成功' : '版本新增成功');
      emit('reloadList');
      onClose();
    } catch (error) {
      smartSentry.captureError(error);
    } finally {
      submitLoading.value = false;
    }
  }

  defineExpose({ showModal });
</script>

<style lang="less" scoped>
  .form-tip {
    margin-bottom: 20px;
  }
</style>
