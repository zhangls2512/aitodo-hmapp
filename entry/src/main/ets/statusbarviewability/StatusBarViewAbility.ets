import { UIExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit'

export default class StatusBarViewAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    session.loadContent('pages/Recommendtodostatusbar')
  }
}