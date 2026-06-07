import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getTeamAccountList, newTeamAccount } from '../common/Account'
import openLink from '../common/Openlink'
import { teamRequest } from '../common/Request'

export interface Response {
  data: Data
}

interface Data {
  teamName: string,
  userCount: number,
  todoCount: number,
  userMaxCount: number,
  todoMaxCount: number,
  userId: string,
  userName: string,
  admin: boolean,
  permission: string[]
}

@Builder
export function LoginteamaccountBuilder() {
  Loginteamaccount()
}

@ComponentV2
struct Loginteamaccount {
  @Local path: string = 'https://api.zhangls2512.cn'
  @Local teamId: string = ''
  @Local userId: string = ''
  @Local password: string = ''
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()

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
              Text('服务器')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Flex({
                wrap: FlexWrap.Wrap,
                space: {
                  main: LengthMetrics.vp(8),
                  cross: LengthMetrics.vp(8)
                }
              }) {
                Row() {
                  Radio({
                    value: '公有云',
                    group: 'server'
                  })
                    .checked(this.path === 'https://api.zhangls2512.cn' ? true : false)
                    .onChange(isChecked => {
                      if (!isChecked) {
                        this.path = ''
                      }
                      if (isChecked) {
                        this.path = 'https://api.zhangls2512.cn'
                      }
                    })
                  Text('公有云')
                }

                Row() {
                  Radio({
                    value: '自建云',
                    group: 'server'
                  })
                    .checked(this.path !== 'https://api.zhangls2512.cn' ? true : false)
                    .onChange(isChecked => {
                      if (!isChecked) {
                        this.path = 'https://api.zhangls2512.cn'
                      }
                      if (isChecked) {
                        this.path = ''
                      }
                    })
                  Text('自建云')
                }
              }
              .layoutWeight(1)
            }

            if (this.path !== 'https://api.zhangls2512.cn') {
              Row() {
                Text('地址')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                TextInput({
                  placeholder: '请输入地址',
                  text: this.path!!
                })
                  .enableAutoSpacing(true)
                  .layoutWeight(1)
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            }
            Row() {
              Text('团队ID')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入团队ID',
                text: this.teamId!!
              })
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(36)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Row() {
              Text('用户ID')
                .enableAutoSpacing(true)
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入用户ID',
                text: this.userId!!
              })
                .contentType(ContentType.USER_NAME)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(8)
                .type(InputType.USER_NAME)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Row() {
              Text('密码')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入密码',
                text: this.password!!
              })
                .contentType(ContentType.PASSWORD)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .maxLength(32)
                .type(InputType.Password)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Button('登录')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .width('100%')
              .onClick(async () => {
                if (!this.path) {
                  await promptAction.openToast({
                    message: '请输入地址'
                  })
                  return
                }
                if (this.teamId.length !== 36) {
                  await promptAction.openToast({
                    message: '请输入正确的团队 ID'
                  })
                  return
                }
                const teamAccountList = await getTeamAccountList()
                if (teamAccountList.find(item => item.teamId === this.teamId)) {
                  await promptAction.openToast({
                    message: '当前已登录此团队的其他账号，请将其退出再登录新账号'
                  })
                  return
                }
                if (this.userId.length !== 8) {
                  await promptAction.openToast({
                    message: '请输入正确的用户 ID'
                  })
                  return
                }
                if (this.password.length < 8) {
                  await promptAction.openToast({
                    message: '请输入正确的密码'
                  })
                  return
                }
                const authorization = 'Basic ' + new util.Base64Helper().encodeToStringSync(
                  new util.TextEncoder().encodeInto(this.teamId + ':' + this.userId + ':' + this.password))
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '请求中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await teamRequest(this.context, this.teamId, '/getUserInfo', undefined, this.path,
                  authorization)
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  const response = JSON.parse(res) as Response
                  await newTeamAccount({
                    id: '',
                    path: this.path,
                    name: response.data.userName,
                    teamId: this.teamId,
                    teamName: response.data.teamName,
                    authorization: authorization,
                    admin: String(response.data.admin)
                  })
                  await promptAction.openToast({
                    message: '登录成功'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshTeam')
                }
              })
            Text('如何获取上述信息？')
              .fontColor($r('sys.color.font_emphasize'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .onClick(async () => {
                await openLink(this.context, 'https://docs.qq.com/doc/p/94cbc15fb6f7fd2eb51afc7549643321381b282d')
              })
          }
          .alignItems(HorizontalAlign.Start)
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
          mainTitle: '登录新账号'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(context => {
      this.pageInfos = context.pathStack
    })
  }
}