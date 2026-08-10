import { FenceExtensionAbility, geoLocationManager } from '@kit.LocationKit'

export class MyFenceExtensionAbility extends FenceExtensionAbility {
  onFenceStatusChange(transition: geoLocationManager.GeofenceTransition) {
  }
}