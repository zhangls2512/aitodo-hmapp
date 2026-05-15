import { common } from '@kit.AbilityKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { generateBarcode, scanCore } from '@kit.ScanKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import {
  hdsEffect,
  hdsMaterial,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType
} from '@kit.UIDesignKit'
import { getPersonalAccountAccessToken } from '../common/Account'
import getDeviceToken from '../common/Devicetoken'
import copy from '../common/Pasteboard'
import request from '../common/Request'

@Builder
export function InviteBuilder() {
  Invite()
}

@ComponentV2
struct Invite {
  @Local deviceToken: string = ''
  @Local invitationcode: string = ''
  @Local inviteusercount: number = -1
  @Local loading: boolean = false
  @Local inputInvitationcode: string = ''
  @Local accessToken: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
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
            if (!this.loading && this.invitationcode && this.inviteusercount !== -1) {
              Text('邀请码')
                .fontWeight(FontWeight.Bold)
              Text(this.invitationcode)
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .onClick(async () => {
                  await copy(this.context, this.UIContext, this.invitationcode)
                })
              Text('邀请链接')
                .fontWeight(FontWeight.Bold)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
              Text('https://www.zhangls2512.cn/product/todo?invitationcode=' + this.invitationcode)
                .fontColor($r('sys.color.font_emphasize'))
                .fontWeight(FontWeight.Medium)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
                .onClick(async () => {
                  const shareData = new systemShare.SharedData({
                    utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
                    title: '邀请您使用轩铭智能待办',
                    description: '邀请您使用轩铭智能待办，方便、智能地记录、管理待办。',
                    thumbnail: this.context.resourceManager.getMediaByNameSync('icon'),
                    content: 'https://www.zhangls2512.cn/product/todo?invitationcode=' + this.invitationcode
                  })
                  const shareController = new systemShare.ShareController(shareData)
                  await shareController.show(this.context, {})
                })
              Row() {
                Text('邀请二维码')
                  .fontWeight(FontWeight.Bold)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Button('分享')
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(async () => {
                    const qrcodeDir = this.context.cacheDir + '/media/invitationqrcode/'
                    const qrcodePath = qrcodeDir + this.invitationcode + '.png'
                    if (!fileIo.accessSync(qrcodePath)) {
                      const qrcodePixelMap =
                        await generateBarcode.createBarcode('https://www.zhangls2512.cn/product/todo?invitationcode=' +
                          this.invitationcode, {
                          scanType: scanCore.ScanType.QR_CODE,
                          width: 200,
                          height: 200
                        })
                      if (!fileIo.accessSync(qrcodeDir)) {
                        await fileIo.mkdir(qrcodeDir, true)
                      }
                      const qrcodeFile =
                        fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                      const imagePacker = image.createImagePacker()
                      await imagePacker.packToFile(qrcodePixelMap, qrcodeFile.fd, {
                        format: 'image/png',
                        quality: 100
                      })
                      await imagePacker.release()
                      await qrcodePixelMap.release()
                      fileIo.closeSync(qrcodeFile)
                    }
                    const qrcodeUri = fileUri.getUriFromPath(qrcodePath)
                    const shareData = new systemShare.SharedData({
                      utd: uniformTypeDescriptor.UniformDataType.IMAGE,
                      title: '邀请您使用轩铭智能待办',
                      description: '邀请您使用轩铭智能待办，方便、智能地记录、管理待办。',
                      thumbnailUri: qrcodeUri,
                      uri: qrcodeUri
                    })
                    const shareController = new systemShare.ShareController(shareData)
                    await shareController.show(this.context, {})
                  })
                Button('保存')
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .visualEffect(new hdsEffect.HdsEffectBuilder()
                    .pointLight({
                      sourceType: hdsEffect.PointLightSourceType.SOFT,
                      illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                    })
                    .buildEffect())
                  .onClick(async () => {
                    const qrcodeDir = this.context.cacheDir + '/media/invitationqrcode/'
                    const qrcodePath = qrcodeDir + this.invitationcode + '.png'
                    if (!fileIo.accessSync(qrcodePath)) {
                      const qrcodePixelMap =
                        await generateBarcode.createBarcode('https://www.zhangls2512.cn/product/todo?invitationcode=' +
                          this.invitationcode, {
                          scanType: scanCore.ScanType.QR_CODE,
                          width: 200,
                          height: 200
                        })
                      if (!fileIo.accessSync(qrcodeDir)) {
                        await fileIo.mkdir(qrcodeDir, true)
                      }
                      const qrcodeFile =
                        fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
                      const imagePacker = image.createImagePacker()
                      await imagePacker.packToFile(qrcodePixelMap, qrcodeFile.fd, {
                        format: 'image/png',
                        quality: 100
                      })
                      await imagePacker.release()
                      await qrcodePixelMap.release()
                      fileIo.closeSync(qrcodeFile)
                    }
                    const qrcodeUri = fileUri.getUriFromPath(qrcodePath)
                    const phAccessHelper = photoAccessHelper.getPhotoAccessHelper(this.context)
                    const uris = await phAccessHelper.showAssetsCreationDialog([qrcodeUri], [{
                      fileNameExtension: 'png',
                      photoType: photoAccessHelper.PhotoType.IMAGE
                    }])
                    await phAccessHelper.release()
                    if (uris.length === 1) {
                      const srcFile = fileIo.openSync(qrcodeUri)
                      const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                      await fileIo.copyFile(srcFile.fd, destFile.fd)
                      fileIo.closeSync(srcFile)
                      fileIo.closeSync(destFile)
                      await promptAction.openToast({
                        message: '保存成功'
                      })
                    }
                  })
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })

              Column() {
                QRCode('https://www.zhangls2512.cn/product/todo?invitationcode=' + this.invitationcode)
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')

              Text('已邀请新用户数：' + this.inviteusercount)
                .fontWeight(FontWeight.Bold)
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
            }
            if (this.loading) {
              LoadingProgress()
                .height(20)
                .width(20)
            }
            TextArea({
              placeholder: '请输入邀请码',
              text: this.inputInvitationcode!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
              .maxLength(62)
              .showCounter(true)
            Button('提交')
              .enabled(this.accessToken !== '' && this.deviceToken !== '' && this.inputInvitationcode.length === 62)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '请求中...'
                  })
                })
                dialogControllerProgress.open()
                const res = await request(this.context, '/product/useInvitationcode', {
                  accessToken: this.accessToken,
                  deviceToken: this.deviceToken,
                  product: 'todo',
                  invitationcode: this.inputInvitationcode
                })
                dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.openToast({
                    message: '验证通过，已获得 10 个永久云备份空间'
                  })
                  this.pageInfos.pop()
                  this.context.eventHub.emit('refreshVip')
                }
              })
            Text('参与活动')
              .fontWeight(FontWeight.Bold)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
            Text('1. 点击复制蓝色的邀请码，发送给新用户，让其进入本页面输入邀请码并提交。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text() {
              Span('2. 点击分享蓝色的邀请链接给新用户，让其')
                .fontWeight(FontWeight.Medium)
              Span('登录轩铭2512统一账号后')
                .fontWeight(FontWeight.Bold)
              Span('访问邀请链接进入本应用。')
                .fontWeight(FontWeight.Medium)
            }
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_text_paragraph_margin_s')
            })

            if (deviceInfo.deviceType !== 'tablet') {
              Text() {
                Span('3. 本设备停留在本页面，让新用户')
                  .fontWeight(FontWeight.Medium)
                Span('登录轩铭2512统一账号后')
                  .fontWeight(FontWeight.Bold)
                Span('与本设备碰一碰/隔空传送进入本应用。')
                  .fontWeight(FontWeight.Medium)
              }
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            }
            Text('活动说明')
              .fontWeight(FontWeight.Bold)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_l')
              })
            Text('1. 其他账号每使用本账号邀请码一次，本账号获得10个永久云备份空间，其他账号获得5个永久云备份空间。')
              .enableAutoSpacing(true)
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_m')
              })
            Text('2. 每个账号、设备仅能使用一次邀请码。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('3. 本账号邀请码可以被不限制数量的其他账号、设备使用，但不可被本账号使用。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
              })
            Text('4. 本账号当前邀请码在取消开通云服务后会失效，重新开通无法恢复 (会生成新的邀请码)。')
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('sys.float.ohos_id_text_paragraph_margin_s')
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
          mainTitle: '邀请新用户，免费得会员'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.accessToken = await getPersonalAccountAccessToken()
      if (this.accessToken) {
        this.loading = true
        this.deviceToken = await getDeviceToken()
        const userres = await request(this.context, '/product/getUserInfo', {
          accessToken: this.accessToken,
          product: 'todo'
        })
        if (userres !== 'fail') {
          this.invitationcode = JSON.parse(userres).data.invitationCode
          if (deviceInfo.deviceType !== 'tablet') {
            const shareData = new systemShare.SharedData({
              utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
              title: '邀请您使用轩铭智能待办',
              description: '邀请您使用轩铭智能待办，方便、智能地记录、管理待办。',
              thumbnail: this.context.resourceManager.getMediaByNameSync('icon'),
              content: 'https://www.zhangls2512.cn/product/todo?invitationcode=' + this.invitationcode
            })
            harmonyShare.on('knockShare', async (sharableTarget) => {
              await sharableTarget.share(shareData)
            })
            harmonyShare.on('gesturesShare', async (sharableTarget) => {
              await sharableTarget.share(shareData)
            })
          }
        }
        const countres = await request(this.context, '/product/getInviteUserCount', {
          accessToken: this.accessToken,
          product: 'todo'
        })
        this.loading = false
        if (countres !== 'fail') {
          this.inviteusercount = JSON.parse(countres).count
        }
      }
    })
    .onDisAppear(() => {
      if (deviceInfo.deviceType !== 'tablet') {
        harmonyShare.off('knockShare')
        harmonyShare.off('gesturesShare')
      }
    })
  }
}