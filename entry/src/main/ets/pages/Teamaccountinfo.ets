import { common } from '@kit.AbilityKit'
import { LengthMetrics, LoadingDialog } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { teamRequest } from '../common/Request'
import { Response } from './Loginteamaccount'

@Builder
export function TeamaccountinfoBuilder() {
  Teamaccountinfo()
}

@ComponentV2
struct Teamaccountinfo {
  @Local teamId: string = ''
  @Local teamName: string = ''
  @Local userId: string = ''
  @Local userName: string = ''
  @Local admin: boolean = false
  @Local permission: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  permissionMap: Record<string, string> = {
    'newTodo': '新增待办',
    'getTodo': '查看待办'
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Column() {
            Row() {
              Text('团队ID')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.teamId)
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
              Text('团队名')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.teamName)
                .enableAutoSpacing(true)
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
              Text('ID')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.userId)
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
              Text('名')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.userName)
                .enableAutoSpacing(true)
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
              Text('管理员')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.admin ? '是' : '否')
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
              Text('权限')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Text(this.permission ? this.permission : '无')
                .fontColor($r('sys.color.font_secondary'))
                .fontSize($r('sys.float.ohos_id_text_size_body2'))
                .layoutWeight(1)
                .textAlign(TextAlign.End)
            }
            .borderRadius(12)
            .padding(12)
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem()
          .margin({
            bottom: 28
          })
      }
      .padding({
        left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
        right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
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
          mainTitle: '账号信息'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.teamId = context.pathInfo.param as string
      const dialogControllerProgress = new CustomDialogController({
        builder: LoadingDialog({
          content: '请求中...'
        })
      })
      dialogControllerProgress.open()
      const res = await teamRequest(this.context, this.teamId, '/getUserInfo')
      dialogControllerProgress.close()
      if (res !== 'fail') {
        const response = JSON.parse(res) as Response
        this.teamName = response.data.teamName
        this.userId = response.data.userId
        this.userName = response.data.userName
        this.admin = response.data.admin
        this.permission = response.data.permission.map(item => this.permissionMap[item]).join('、')
      }
    })
  }
}