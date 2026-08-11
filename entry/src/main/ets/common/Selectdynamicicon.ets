import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { appInfoManager } from '@kit.AppGalleryKit'
import { uiAppearance } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { getFlushPreference } from './Preference'

export async function selectDynamicIcon(context: common.UIAbilityContext) {
  const iconMode = getFlushPreference(context, 'commonSetting', 'iconMode', 1)
  const colorMode = getFlushPreference(context, 'commonSetting', 'colorMode', 0)
  try {
    if (iconMode === 0) {
      if (colorMode === 0) {
        const systemColorMode = uiAppearance.getDarkMode()
        if (systemColorMode === uiAppearance.DarkMode.ALWAYS_DARK) {
          await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
        }
        if (systemColorMode === uiAppearance.DarkMode.ALWAYS_LIGHT) {
          await appInfoManager.disableDynamicIcon()
        }
      }
      if (colorMode === 1) {
        await appInfoManager.disableDynamicIcon()
      }
      if (colorMode === 2) {
        await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
      }
      if (colorMode === 3) {
        if (context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
          await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
        }
        if (context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
          await appInfoManager.disableDynamicIcon()
        }
      }
    }
    if (iconMode === 1) {
      await appInfoManager.disableDynamicIcon()
    }
    if (iconMode === 2) {
      await appInfoManager.selectDynamicIcon('dark_' + deviceInfo.deviceType)
    }
  } catch {
  }
}