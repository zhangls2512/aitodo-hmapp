import { common } from '@kit.AbilityKit'
import { LengthMetrics } from '@kit.ArkUI'
import { iap } from '@kit.IAPKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalAccountAccessToken } from '../common/Account'
import { developerRequest } from '../common/Request'
import { getTimeStringFromTimeStamp } from '../common/Stringformat'

interface Item {
  duration: number,
  type: string,
  info: string,
  date: number
}

@Builder
export function ViplogBuilder() {
  Viplog()
}

@ComponentV2
struct Viplog {
  @Local viplogArray: Item[] = []
  @Local loading: boolean = false
  @Local hoverId: number | string = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  accessToken = ''
  lastCount = -1

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        if (this.viplogArray.length === 0 && !this.loading) {
          ListItem() {
            Text('无数据')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ForEach(this.viplogArray, (item: Item, index) => {
          ListItem() {
            Column() {
              Row() {
                Text('个数')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(String(item.duration))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('类型')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.type === 'pay' ? '付费' :
                  item.type === 'vipcode' ? '兑换码' :
                    item.type === 'invitationcode' ? '邀请码' :
                      item.type === 'invitenewuser' ? '邀请新用户' : 'undefined')
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('详情')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(item.info)
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('时间')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Text(getTimeStringFromTimeStamp(item.date))
                  .fontColor($r('sys.color.font_secondary'))
                  .fontSize($r('sys.float.ohos_id_text_size_body2'))
                  .layoutWeight(1)
                  .textAlign(TextAlign.End)
              }
              .borderRadius(12)
              .padding(12)

              if (item.type === 'pay') {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('申请退款')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
                }
                .borderRadius(12)
                .padding(12)
                .stateStyles({
                  normal: {
                    .backgroundColor(this.hoverId === index + ',0' ? $r('sys.color.interactive_hover') :
                      $r('sys.color.ohos_id_color_card_bg'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .onHover(isHover => {
                  if (!isHover) {
                    this.hoverId = -1
                  }
                  if (isHover) {
                    this.hoverId = index + ',0'
                  }
                })
                .onClick(async () => {
                  try {
                    await iap.createRefundRequest(this.UIContext.getHostContext(), item.info)
                  } catch {
                  }
                })

                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('申请发票')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Image($r('app.media.right'))
                    .fillColor($r('sys.color.icon_fourth'))
                    .height(12)
                    .width(12)
                }
                .borderRadius(12)
                .padding(12)
                .stateStyles({
                  normal: {
                    .backgroundColor(this.hoverId === index + ',1' ? $r('sys.color.interactive_hover') :
                      $r('sys.color.ohos_id_color_card_bg'))
                  },
                  pressed: {
                    .backgroundColor($r('sys.color.interactive_pressed'))
                  }
                })
                .onHover(isHover => {
                  if (!isHover) {
                    this.hoverId = -1
                  }
                  if (isHover) {
                    this.hoverId = index + ',1'
                  }
                })
                .onClick(async () => {
                  try {
                    await iap.showManagedInvoices(this.UIContext.getHostContext(), item.info)
                  } catch {
                  }
                })
              }
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        })
        if (this.loading) {
          ListItem() {
            LoadingProgress()
              .width('20%')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .width('100%')
        }
        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
      })
      .onReachEnd(async () => {
        if (this.accessToken && this.viplogArray.length > 0 && this.lastCount === 10) {
          this.loading = true
          const res = await developerRequest(this.context, '/product/getViplogList', {
            accessToken: this.accessToken,
            product: 'todo',
            skip: this.viplogArray.length
          })
          this.loading = false
          if (res !== 'fail') {
            const array = JSON.parse(res).data as Item[]
            this.lastCount = array.length
            this.viplogArray = this.viplogArray.concat(array)
          }
        }
      })
    }
    .backgroundColor($r('app.color.sheet_background'))
    .recoverable(true)
    .titleBar({
      padding: {
        end: LengthMetrics.vp(60)
      },
      style: {
        scrollEffectOpts: {
          scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
        },
        originalStyle: {
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary')
            },
            backIconStyle: {
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        thermoCtrl: true,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.ADAPTIVE,
          materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
        }
      },
      content: {
        title: {
          mainTitle: '会员开通记录'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onAppear(async () => {
      this.accessToken = await getPersonalAccountAccessToken()
      if (this.accessToken) {
        this.loading = true
        const res = await developerRequest(this.context, '/product/getViplogList', {
          accessToken: this.accessToken,
          product: 'todo'
        })
        this.loading = false
        if (res !== 'fail') {
          this.viplogArray = JSON.parse(res).data
          this.lastCount = this.viplogArray.length
        }
      }
    })
  }
}