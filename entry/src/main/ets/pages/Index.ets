import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { LoadingDialog } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import {
  hdsMaterial,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsSideMenu,
  HdsSideMenuMainItem,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType
} from '@kit.UIDesignKit'
import { getPersonalAccountAccessToken } from '../common/Account'
import { getKeyAlg } from '../common/Crypto'
import { importTodo } from '../common/Dataimport'
import getDeviceToken from '../common/Devicetoken'
import { readUri } from '../common/File'
import { icsparse } from '../common/Ics'
import { getPreferType } from '../common/Prefertype'
import { developerRequest } from '../common/Request'
import Cleardata from './Cleardata'
import Me from './Me'
import Notice from './Notice'
import Recommendtodo from './Recommendtodo'
import Todo from './Todo'
import Uploaderrorlog from './Uploaderrorlog'

@Entry
@ComponentV2
struct Index {
  @Provider() isShowUploaderrorlogSheet: boolean = false
  @Local errorType: string = ''
  @Local errorObject: string = ''
  @Local backgroundImagePixelMap: PixelMap | undefined = undefined
  @Local preferType: number = 1
  @Local index: number = 0
  @Local isShowCleardataSheet: boolean = false
  @Local isShowNoticeSheet: boolean = false
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  controller = new HdsTabsController()

  async getBackgroundImage() {
    const backgroundImagePath = this.context.filesDir + '/media/backgroundimage.png'
    const res = fileIo.accessSync(backgroundImagePath)
    if (res) {
      const backgroundImageSource = image.createImageSource(backgroundImagePath)
      const backgroundImagePixelMap = await backgroundImageSource.createPixelMap()
      await backgroundImageSource.release()
      return backgroundImagePixelMap
    }
    return
  }

  @Builder
  tabBuilder(index: number, image: Resource, title: string) {
    Column() {
      Image(image)
        .fillColor(this.index === index ? $r('sys.color.icon_emphasize') : $r('sys.color.icon_secondary'))
        .height(24)
        .width(24)
      Text(title)
        .fontColor(this.index === index ? $r('sys.color.font_emphasize') : '')
        .fontSize($r('sys.float.ohos_id_text_size_body3'))
        .margin({
          top: 4
        })
    }
  }

  @Builder
  CleardataSheetBuilder() {
    Cleardata()
  }

  @Builder
  NoticeSheetBuilder() {
    Notice()
  }

  @Builder
  UploaderrorlogSheetBuilder() {
    Uploaderrorlog({
      errorType: this.errorType,
      errorObject: this.errorObject
    })
  }

  build() {
    Column() {
      if (deviceInfo.deviceType !== '2in1') {
        HdsTabs({
          controller: this.controller
        }) {
          TabContent() {
            HdsNavigation() {
              Recommendtodo()
                .padding({
                  top: 56
                })
            }
            .hideBackButton(true)
            .mode(NavigationMode.Stack)
            .padding({
              top: 36
            })
            .recoverable(true)
            .titleBar({
              content: {
                title: {
                  mainTitle: '推荐'
                }
              }
            })
            .titleMode(HdsNavigationTitleMode.MINI)
          }
          .tabBar(this.tabBuilder(0, $r('app.media.recommend'), '推荐'))
          .bindSheet(this.isShowNoticeSheet!!, this.NoticeSheetBuilder(), {
            preferType: this.preferType,
            title: {
              title: '消息通知'
            }
          })

          TabContent() {
            HdsNavigation() {
              Todo()
                .padding({
                  top: 56
                })
            }
            .hideBackButton(true)
            .mode(NavigationMode.Stack)
            .padding({
              top: 36
            })
            .recoverable(true)
            .titleBar({
              content: {
                title: {
                  mainTitle: '待办'
                }
              }
            })
            .titleMode(HdsNavigationTitleMode.MINI)
          }
          .tabBar(this.tabBuilder(1, $r('app.media.todo'), '待办'))

          TabContent() {
            HdsNavigation() {
              Me()
            }
            .hideBackButton(true)
            .mode(NavigationMode.Stack)
            .padding({
              top: 36
            })
            .recoverable(true)
            .titleBar({
              style: {
                scrollEffectOpts: {
                  scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR
                },
                originalStyle: {
                  contentStyle: {
                    titleStyle: {
                      mainTitleColor: $r('sys.color.font_primary')
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
                  mainTitle: '我的'
                }
              }
            })
            .titleMode(HdsNavigationTitleMode.MINI)
          }
          .tabBar(this.tabBuilder(2, $r('app.media.me'), '我的'))
        }
        .barBackgroundBlurStyle(BlurStyle.Regular)
        .barFloatingStyle({
          barBottomMargin: 24,
          adaptToHandedness: true,
          thermoCtrl: true,
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.ADAPTIVE,
            materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE
          }
        })
        .barOverlap(true)
        .barPosition(BarPosition.End)
        .barWidth(240)
        .scrollable(false)
        .onChange(index => {
          this.index = index
        })
        .onAnimationStart((index, targetIndex) => {
          if (targetIndex === 0) {
            this.context.eventHub.emit('refreshRecommendtodo')
          }
          if (targetIndex === 1) {
            this.context.eventHub.emit('refreshTodo')
          }
          if (targetIndex === 2) {
            this.context.eventHub.emit('refreshMe')
          }
        })
        .bindSheet(this.isShowUploaderrorlogSheet!!, this.UploaderrorlogSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '上传故障日志'
          }
        })
      }
      if (deviceInfo.deviceType === '2in1') {
        Row() {
          HdsSideMenu({
            items: [
              new HdsSideMenuMainItem({
                icon: $r('app.media.recommend_tab'),
                label: '推荐'
              }),
              new HdsSideMenuMainItem({
                icon: $r('app.media.todo_tab'),
                label: '待办'
              }),
              new HdsSideMenuMainItem({
                icon: $r('app.media.me_tab'),
                label: '我的'
              })
            ],
            selectedIndex: 0,
            $selectedIndex: (index) => {
              this.index = index
              if (index === 0) {
                this.context.eventHub.emit('refreshRecommendtodo')
              }
              if (index === 1) {
                this.context.eventHub.emit('refreshTodo')
              }
              if (index === 2) {
                this.context.eventHub.emit('refreshMe')
              }
            }
          })
            .padding({
              top: $r('sys.float.ohos_id_default_padding_top')
            })
            .width(240)
            .bindSheet(this.isShowNoticeSheet!!, this.NoticeSheetBuilder(), {
              preferType: this.preferType,
              title: {
                title: '消息通知'
              }
            })
          Divider()
            .vertical(true)
          if (this.index === 0) {
            Recommendtodo()
              .layoutWeight(1)
          }
          if (this.index === 1) {
            Todo()
              .layoutWeight(1)
          }
          if (this.index === 2) {
            Me()
              .layoutWeight(1)
          }
        }
        .alignItems(VerticalAlign.Top)
        .bindSheet(this.isShowUploaderrorlogSheet!!, this.UploaderrorlogSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '上传故障日志'
          }
        })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .backgroundColor($r('sys.color.background_secondary'))
    .backgroundImage(this.backgroundImagePixelMap)
    .backgroundImageSize(ImageSize.FILL)
    .onAppear(async () => {
      this.context.eventHub.on('clearData', () => {
        if (!this.isShowCleardataSheet) {
          this.isShowCleardataSheet = true
        }
      })
      this.context.eventHub.on('notice', () => {
        if (!this.isShowNoticeSheet) {
          this.isShowNoticeSheet = true
        }
      })
      const promptAction = this.UIContext.getPromptAction()
      this.context.eventHub.on('wantUri', async (wantUri: string) => {
        if (wantUri.endsWith('.txt') || wantUri.endsWith('.vcs') || wantUri.endsWith('.ics')) {
          const filestring = await readUri(wantUri)
          if (wantUri.endsWith('.txt')) {
            await importTodo(this.context, filestring, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
            this.context.eventHub.emit('refreshRecommendtodo')
            this.context.eventHub.emit('refreshTodo')
            await promptAction.openToast({
              message: '导入成功'
            })
          }
          if (wantUri.endsWith('.vcs') || wantUri.endsWith('.ics')) {
            await importTodo(this.context, JSON.stringify({
              encrypted: false,
              data: icsparse(filestring)
            }), relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
            this.context.eventHub.emit('refreshRecommendtodo')
            this.context.eventHub.emit('refreshTodo')
            await promptAction.openToast({
              message: '导入成功'
            })
          }
        }
        const accessToken = await getPersonalAccountAccessToken()
        const dialogControllerProgress = new CustomDialogController({
          builder: LoadingDialog({
            content: '请求中...'
          })
        })
        if (wantUri.startsWith('https://www.zhangls2512.cn/product/todo')) {
          const urires = new uri.URI(wantUri)
          const share = urires.getQueryValue('share')
          const invitationCode = urires.getQueryValue('invitationcode')
          const vipCode = urires.getQueryValue('vipcode')
          if (share) {
            await importTodo(this.context, share, relationalStore.ConflictResolution.ON_CONFLICT_IGNORE)
            await promptAction.openToast({
              message: '导入成功'
            })
            this.context.eventHub.emit('refreshRecommendtodo')
            this.context.eventHub.emit('refreshTodo')
          }
          if (invitationCode) {
            if (!accessToken) {
              await promptAction.showDialog({
                title: '提示',
                message: '邀请码使用失败，原因：未登录账号',
                buttons: [
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
            }
            if (accessToken) {
              const deviceToken = await getDeviceToken()
              if (deviceToken) {
                dialogControllerProgress.open()
                const res = await developerRequest(this.context, '/product/useInvitationcode', {
                  accessToken: accessToken,
                  deviceToken: deviceToken,
                  product: 'todo',
                  invitationcode: invitationCode
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.showDialog({
                    title: '提示',
                    message: '邀请码使用成功',
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                }
              }
            }
          }
          if (vipCode) {
            if (!accessToken) {
              await promptAction.showDialog({
                title: '提示',
                message: '兑换码使用失败，原因：未登录账号',
                buttons: [
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
            }
            if (accessToken) {
              dialogControllerProgress.open()
              const res = await developerRequest(this.context, '/product/useVipcode', {
                accessToken: accessToken,
                vipcode: vipCode
              })
              dialogControllerProgress.close()
              if (res !== 'fail') {
                await promptAction.showDialog({
                  title: '提示',
                  message: '兑换码使用成功',
                  buttons: [
                    {
                      text: '确定',
                      color: $r('sys.color.font_emphasize')
                    }
                  ]
                })
              }
            }
          }
        }
        if (wantUri.startsWith('https://www.zhangls2512.cn/product/account/login')) {
          const urires = new uri.URI(wantUri)
          const ticket = urires.getQueryValue('ticket')
          if (!ticket) {
            await promptAction.showDialog({
              title: '提示',
              message: '链接格式错误',
              buttons: [
                {
                  text: '确定',
                  color: $r('sys.color.font_emphasize')
                }
              ]
            })
          }
          if (ticket) {
            const accessToken = await getPersonalAccountAccessToken()
            if (!accessToken) {
              await promptAction.showDialog({
                title: '提示',
                message: '扫码登录失败，原因：未登录账号',
                buttons: [
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
            }
            if (accessToken) {
              const confirm = await promptAction.showDialog({
                title: '提示',
                message: '确定登录？',
                buttons: [
                  {
                    text: '取消',
                    color: $r('sys.color.font_primary')
                  },
                  {
                    text: '确定',
                    color: $r('sys.color.font_emphasize')
                  }
                ]
              })
              if (confirm.index === 1) {
                dialogControllerProgress.open()
                const res = await developerRequest(this.context, '/account/confirmTicket', {
                  accessToken: accessToken,
                  ticket: ticket
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.showDialog({
                    title: '提示',
                    message: '确定成功',
                    buttons: [
                      {
                        text: '确定',
                        color: $r('sys.color.font_emphasize')
                      }
                    ]
                  })
                }
              }
            }
          }
        }
      })
      this.context.eventHub.on('dialog', async (title: string, message: string) => {
        await promptAction.showDialog({
          title: title,
          message: message,
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      })
      this.context.eventHub.on('uploadErrorLog', (errorType: string, errorObject: string) => {
        this.errorType = errorType
        this.errorObject = errorObject
        this.isShowUploaderrorlogSheet = true
      })
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshIndex', async () => {
        this.backgroundImagePixelMap = await this.getBackgroundImage()
      })
      this.backgroundImagePixelMap = await this.getBackgroundImage()
      if (!getKeyAlg()) {
        await promptAction.showDialog({
          title: '提示',
          message: '检测到未导入密钥，建议前往“我的”>“设置”>“密钥”导入密钥以加密数据，提高安全性',
          buttons: [
            {
              text: '确定',
              color: $r('sys.color.font_emphasize')
            }
          ]
        })
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshIndex')
      this.context.eventHub.off('uploadErrorLog')
      this.context.eventHub.off('dialog')
      this.context.eventHub.off('wantUri')
      this.context.eventHub.off('notice')
      this.context.eventHub.off('clearData')
    })
    .bindSheet(this.isShowCleardataSheet!!, this.CleardataSheetBuilder(), {
      preferType: this.preferType
    })
  }
}