import { common } from '@kit.AbilityKit'
import { LengthMetrics, promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getWebdavServerInfo, setWebdavServer } from '../common/Webdavserver'

@Builder
export function WebdavserverBuilder() {
  Webdavserver()
}

@ComponentV2
struct Webdavserver {
  @Local path: string = ''
  @Local username: string = ''
  @Local password: string = ''
  @Local pathInputFocus: boolean = false
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  accountExist = false

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        ListItem() {
          Column() {
            TextInput({
              placeholder: '请输入地址',
              text: this.path!!
            })
              .defaultFocus(this.pathInputFocus)
              .enableAutoSpacing(true)
            TextInput({
              placeholder: '请输入用户名',
              text: this.username!!
            })
              .contentType(ContentType.USER_NAME)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.USER_NAME)
            TextInput({
              placeholder: '请输入密码',
              text: this.password!!
            })
              .contentType(ContentType.PASSWORD)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.Password)
            Button('保存')
              .keyboardShortcut('S', [ModifierKey.CTRL])
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .width('100%')
              .onClick(async () => {
                if (!this.path) {
                  if (!this.accountExist) {
                    if (!this.path) {
                      await promptAction.openToast({
                        message: '请输入地址'
                      })
                      return
                    }
                  }
                  if (this.accountExist) {
                    const appAccountManager = appAccount.createAppAccountManager()
                    await appAccountManager.removeAccount('webdavserver')
                  }
                }
                if (this.path) {
                  if (!this.path.startsWith('https://')) {
                    await promptAction.openToast({
                      message: '为保障备份数据安全，仅支持使用 HTTPS 协议 WebDAV 服务器'
                    })
                    return
                  }
                  if (this.path.endsWith('/')) {
                    await promptAction.openToast({
                      message: '系统自动添加路径分隔符，无需手动在地址末尾添加'
                    })
                    return
                  }
                  if (!this.username) {
                    await promptAction.openToast({
                      message: '请输入用户名'
                    })
                    return
                  }
                  if (!this.password) {
                    await promptAction.openToast({
                      message: '请输入密码'
                    })
                    return
                  }
                  await setWebdavServer({
                    path: this.path,
                    username: this.username,
                    password: this.password
                  })
                }
                await promptAction.openToast({
                  message: '保存成功'
                })
                this.pageInfos.pop()
                this.context.eventHub.emit('refreshDataBackupRecovery')
              })
            Text('地址示例：https://example.com:5006/todobackup')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
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
          mainTitle: 'WebDAV 服务器'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      const webdavServerInfo = await getWebdavServerInfo()
      this.path = webdavServerInfo.path
      this.username = webdavServerInfo.username
      this.password = webdavServerInfo.password
      if (!this.path) {
        this.pathInputFocus = true
      }
      if (this.path) {
        this.accountExist = true
      }
    })
  }
}