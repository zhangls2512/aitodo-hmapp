import { UIAbility } from '@kit.AbilityKit'
import { commonEventManager } from '@kit.BasicServicesKit'

export default class BackgroundAbility extends UIAbility {
  onDestory() {
    commonEventManager.publish('BACKGROUNDABILITY_EVENT_DESTROY', {
      bundleName: 'com.zhangxm.aitodo'
    }, () => {
    })
  }
}