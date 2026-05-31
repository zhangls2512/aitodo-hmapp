import { UIExtensionContentSession, Want } from '@kit.AbilityKit'

export default class StatusBarViewAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    session.loadContent('pages/Recommendtodostatusbar')
  }
}