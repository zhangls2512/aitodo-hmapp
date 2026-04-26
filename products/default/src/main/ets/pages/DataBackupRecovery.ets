import { common } from '@kit.AbilityKit'
import { relationalStore } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { appAccount } from '@kit.BasicServicesKit'
import { fileIo, picker } from '@kit.CoreFileKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getCaldavServerInfo } from '../common/Caldavserver'
import { importTodo } from '../common/Dataimport'
import { read } from '../common/File'
import { icsparse } from '../common/Ics'
import { checkPermission } from '../common/Permission'
import { getFlushPreference, setFlushPreference } from '../common/Preference'
import { backupTable, caldavBackupTable, fileBackupTable, recoveryTable, webdavBackupTable } from '../common/Table'
import { getWebdavServerInfo } from '../common/Webdavserver'

@Builder
export function DataBackupRecoveryBuilder() {
  DataBackupRecovery()
}

@ComponentV2
struct DataBackupRecovery {
  @Local isBackup: boolean = false
  @Local index: number = 0
  @Local value: string = '保留'
  @Local webdavAccountDataSyncEnabled: boolean = false
  @Local caldavAccountDataSyncEnabled: boolean = false
  @Local webdavAccountDataSync: boolean = false
  @Local caldavAccountDataSync: boolean = false
  @Local hoverId: number = -1
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  autoBackup = false
  encryptFileBackup = true
  autoFileBackup = false
  encryptWebdavBackup = true
  autoWebdavBackup = false
  autoCaldavBackup = false
  pauseAutoBackupWhenLowBatteryCapacityLevel = false
  pauseAutoBackupWhenPowerSave = false
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  async getSetting() {
    if (fileIo.accessSync(this.context.databaseDir + '/rdb/todobackup.db')) {
      this.isBackup = true
    }
    this.autoBackup = getFlushPreference(this.context, 'dataSetting', 'autoBackup', true) as boolean
    this.encryptFileBackup = getFlushPreference(this.context, 'dataSetting', 'encryptFileBackup', true) as boolean
    this.autoFileBackup = getFlushPreference(this.context, 'dataSetting', 'autoFileBackup', true) as boolean
    this.encryptWebdavBackup = getFlushPreference(this.context, 'dataSetting', 'encryptWebdavBackup', true) as boolean
    this.autoWebdavBackup = getFlushPreference(this.context, 'dataSetting', 'autoWebdavBackup', true) as boolean
    this.autoCaldavBackup = getFlushPreference(this.context, 'dataSetting', 'autoCaldavBackup', true) as boolean
    this.pauseAutoBackupWhenLowBatteryCapacityLevel =
      getFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenLowBatteryCapacityLevel', false) as boolean
    this.pauseAutoBackupWhenPowerSave =
      getFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenPowerSave', false) as boolean
    const res = await checkPermission(this.context, this.UIContext, 'ohos.permission.DISTRIBUTED_DATASYNC')
    this.webdavAccountDataSyncEnabled = res
    this.caldavAccountDataSyncEnabled = res
    const webdavServerInfo = await getWebdavServerInfo()
    if (!webdavServerInfo.path) {
      this.webdavAccountDataSyncEnabled = false
    }
    if (webdavServerInfo.path) {
      if (res) {
        const appAccountManager = appAccount.createAppAccountManager()
        this.webdavAccountDataSync = await appAccountManager.checkDataSyncEnabled('webdavserver')
      }
    }
    const caldavServerInfo = await getCaldavServerInfo()
    if (!caldavServerInfo.path) {
      this.caldavAccountDataSyncEnabled = false
    }
    if (caldavServerInfo.path) {
      if (res) {
        const appAccountManager = appAccount.createAppAccountManager()
        this.caldavAccountDataSync = await appAccountManager.checkDataSyncEnabled('caldavserver')
      }
    }
  }

  async getWebdavBackup() {
    const webdavServerInfo = await getWebdavServerInfo()
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' +
            webdavServerInfo.password))
      }
    })
    try {
      const response = await session.get(webdavServerInfo.path + '/todo.txt')
      session.close()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        const body = String(response)
        if (!body) {
          await promptAction.openToast({
            message: '备份文件内容为空，无法恢复'
          })
          return 'fail'
        }
        return body
      }
      const statusCodeMap: Record<number, string> = {
        401: '账号密码错误',
        404: '无备份文件',
        405: '目录不存在或无权限'
      }
      const reason = statusCodeMap[response.statusCode]
      if (reason) {
        await promptAction.openToast({
          message: '恢复失败，原因：' + reason
        })
        return 'fail'
      }
      await promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
      })
      return 'fail'
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }

  async getCaldavBackup() {
    const caldavServerInfo = await getCaldavServerInfo()
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' +
            caldavServerInfo.password))
      }
    })
    try {
      const response = await session.get(caldavServerInfo.path + '/todo.ics')
      session.close()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        const body = String(response)
        if (!body) {
          await promptAction.openToast({
            message: '备份文件内容为空，无法恢复'
          })
          return 'fail'
        }
        return body
      }
      const statusCodeMap: Record<number, string> = {
        401: '账号密码错误',
        403: '备份不存在或无权限'
      }
      const reason = statusCodeMap[response.statusCode]
      if (reason) {
        await promptAction.openToast({
          message: '恢复失败，原因：' + reason
        })
        return 'fail'
      }
      await promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
      })
      return 'fail'
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }

  async deleteWebdavBackup() {
    const webdavServerInfo = await getWebdavServerInfo()
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(webdavServerInfo.username + ':' +
            webdavServerInfo.password))
      }
    })
    try {
      const response = await session.delete(webdavServerInfo.path + '/todo.txt')
      session.close()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'success'
      }
      const statusCodeMap: Record<number, string> = {
        401: '账号密码错误',
        404: '无备份文件',
        405: '目录不存在或无权限'
      }
      const reason = statusCodeMap[response.statusCode]
      if (reason) {
        await promptAction.openToast({
          message: '删除失败，原因：' + reason
        })
        return 'fail'
      }
      await promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
      })
      return 'fail'
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
  }

  async deleteCaldavBackup() {
    const caldavServerInfo = await getCaldavServerInfo()
    const session = rcp.createSession({
      requestConfiguration: {
        security: {
          tlsRange: {
            min: 'TlsV1.2'
          }
        }
      },
      headers: {
        Authorization: 'Basic ' +
          new util.Base64Helper().encodeToStringSync(new util.TextEncoder().encodeInto(caldavServerInfo.username + ':' +
            caldavServerInfo.password))
      }
    })
    try {
      const response = await session.delete(caldavServerInfo.path + '/todo.ics')
      session.close()
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return 'success'
      }
      const statusCodeMap: Record<number, string> = {
        401: '账号密码错误',
        403: '备份不存在或无权限'
      }
      const reason = statusCodeMap[response.statusCode]
      if (reason) {
        await promptAction.openToast({
          message: '删除失败，原因：' + reason
        })
        return 'fail'
      }
      await promptAction.openToast({
        message: '请求失败，错误码：' + response.statusCode
      })
      return 'fail'
    } catch (err) {
      session.close()
      await promptAction.openToast({
        message: '发生错误，错误码：' + err.code
      })
      return 'fail'
    }
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
            Text('数据库')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('自动备份')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoBackup!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'autoBackup', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('手动备份')
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
                  .backgroundColor(this.hoverId === 0 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 0
                }
              })
              .onClick(async () => {
                await backupTable(this.context)
                await promptAction.openToast({
                  message: '备份成功'
                })
                await this.getSetting()
              })

              if (this.isBackup) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('恢复')
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
                    .backgroundColor(this.hoverId === 1 ? $r('sys.color.interactive_hover') :
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
                    this.hoverId = 1
                  }
                })
                .onClick(async () => {
                  await recoveryTable(this.context)
                  await promptAction.openToast({
                    message: '恢复成功'
                  })
                })
              }
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
        })

        ListItem() {
          Column() {
            Text('文件')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Column() {
                  Text('加密')
                    .fontWeight(FontWeight.Medium)
                  Text('在“我的”>“设置”>“密钥”导入密钥后生效')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })

                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.encryptFileBackup!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'encryptFileBackup', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('冲突解决模式')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Select([
                  { value: '保留' },
                  { value: '覆盖' }
                ])
                  .selected(this.index!!)
                  .value(this.value!!)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('自动备份')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoFileBackup!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'autoFileBackup', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('手动备份')
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
                  .backgroundColor(this.hoverId === 2 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 2
                }
              })
              .onClick(async () => {
                await fileBackupTable(this.context)
                await promptAction.openToast({
                  message: '备份成功'
                })
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('恢复')
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
                  .backgroundColor(this.hoverId === 3 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 3
                }
              })
              .onClick(async () => {
                const filePath = this.context.filesDir + '/backup/todo.txt'
                if (!fileIo.accessSync(filePath)) {
                  await promptAction.openToast({
                    message: '无备份文件，无法恢复'
                  })
                  return
                }
                const filestring = await read(filePath)
                let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                if (this.index === 1) {
                  conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                }
                const res = await importTodo(this.context, filestring, conflictResolution)
                if (res === 'success') {
                  await promptAction.openToast({
                    message: '恢复成功'
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('导出备份')
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
                  .backgroundColor(this.hoverId === 4 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 4
                }
              })
              .onClick(async () => {
                const filePath = this.context.filesDir + '/backup/todo.txt'
                if (!fileIo.accessSync(filePath)) {
                  await promptAction.openToast({
                    message: '无备份文件，无需导出'
                  })
                  return
                }
                const documentSaveOptions = new picker.DocumentSaveOptions()
                documentSaveOptions.newFileNames = ['todo']
                documentSaveOptions.fileSuffixChoices = ['.txt']
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.save(documentSaveOptions)
                if (uris.length === 1) {
                  const srcFile = fileIo.openSync(filePath)
                  const destFile = fileIo.openSync(uris[0], fileIo.OpenMode.WRITE_ONLY)
                  await fileIo.copyFile(srcFile.fd, destFile.fd)
                  fileIo.closeSync(srcFile)
                  fileIo.closeSync(destFile)
                  await promptAction.openToast({
                    message: '导出成功'
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('删除备份')
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
                  .backgroundColor(this.hoverId === 5 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 5
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const filePath = this.context.filesDir + '/backup/todo.txt'
                if (!fileIo.accessSync(filePath)) {
                  await promptAction.openToast({
                    message: '无备份文件，无需删除'
                  })
                  return
                }
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '删除成功后无法恢复，确定删除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '确定',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  await fileIo.unlink(filePath)
                  await promptAction.openToast({
                    message: '删除成功'
                  })
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('WebDAV')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('WebDAV服务器')
                  .enableAutoSpacing(true)
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
                  .backgroundColor(this.hoverId === 6 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 6
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Webdavserver'
                })
              })

              if (this.webdavAccountDataSyncEnabled) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('设备间同步')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.webdavAccountDataSync!!
                  })
                    .onChange(async (isOn) => {
                      try {
                        const appAccountManager = appAccount.createAppAccountManager()
                        await appAccountManager.setDataSyncEnabled('webdavserver', isOn)
                      } catch (err) {
                        this.webdavAccountDataSync = false
                        await promptAction.openToast({
                          message: '发生错误，错误码：' + err.code
                        })
                      }
                    })
                }
                .borderRadius(12)
                .padding(12)
              }
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Column() {
                  Text('加密')
                    .fontWeight(FontWeight.Medium)
                  Text('在“我的”>“设置”>“密钥”导入密钥后生效')
                    .fontColor($r('sys.color.font_secondary'))
                    .fontSize($r('sys.float.ohos_id_text_size_body2'))
                    .margin({
                      top: $r('sys.float.ohos_id_text_margin_vertical')
                    })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })

                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.encryptWebdavBackup!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'encryptWebdavBackup', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('冲突解决模式')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Select([
                  { value: '保留' },
                  { value: '覆盖' }
                ])
                  .selected(this.index!!)
                  .value(this.value!!)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('自动备份')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoWebdavBackup!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'autoWebdavBackup', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('手动备份')
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
                  .backgroundColor(this.hoverId === 7 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 7
                }
              })
              .onClick(async () => {
                const webdavServerInfo = await getWebdavServerInfo()
                if (!webdavServerInfo.path) {
                  await promptAction.openToast({
                    message: '未配置 WebDAV 服务器，无法备份'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const res = await webdavBackupTable(this.context)
                this.dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.openToast({
                    message: '备份成功'
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('恢复')
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
                  .backgroundColor(this.hoverId === 8 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 8
                }
              })
              .onClick(async () => {
                const webdavServerInfo = await getWebdavServerInfo()
                if (!webdavServerInfo.path) {
                  await promptAction.openToast({
                    message: '未配置 WebDAV 服务器，无法恢复'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const filestring = await this.getWebdavBackup()
                this.dialogControllerProgress.close()
                if (filestring !== 'fail') {
                  let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                  if (this.index === 1) {
                    conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                  }
                  const res = await importTodo(this.context, filestring, conflictResolution)
                  if (res === 'success') {
                    await promptAction.openToast({
                      message: '恢复成功'
                    })
                  }
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('删除备份')
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
                  .backgroundColor(this.hoverId === 9 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 9
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const webdavServerInfo = await getWebdavServerInfo()
                if (!webdavServerInfo.path) {
                  await promptAction.openToast({
                    message: '未配置 WebDAV 服务器，无法删除'
                  })
                  return
                }
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '删除成功后无法恢复，确定删除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '确定',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.dialogControllerProgress.open()
                  const res = await this.deleteWebdavBackup()
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('CalDAV')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('CalDAV服务器')
                  .enableAutoSpacing(true)
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
                  .backgroundColor(this.hoverId === 10 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 10
                }
              })
              .onClick(() => {
                this.pageInfos.pushPath({
                  name: 'Caldavserver'
                })
              })

              if (this.caldavAccountDataSyncEnabled) {
                Divider()
                  .padding({
                    left: 12,
                    right: 12
                  })
                Row() {
                  Text('设备间同步')
                    .fontWeight(FontWeight.Medium)
                    .layoutWeight(1)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  Toggle({
                    type: ToggleType.Switch,
                    isOn: this.caldavAccountDataSync!!
                  })
                    .onChange(async (isOn) => {
                      try {
                        const appAccountManager = appAccount.createAppAccountManager()
                        await appAccountManager.setDataSyncEnabled('caldavserver', isOn)
                      } catch (err) {
                        this.caldavAccountDataSync = false
                        await promptAction.openToast({
                          message: '发生错误，错误码：' + err.code
                        })
                      }
                    })
                }
                .borderRadius(12)
                .padding(12)
              }
              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('冲突解决模式')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Select([
                  { value: '保留' },
                  { value: '覆盖' }
                ])
                  .selected(this.index!!)
                  .value(this.value!!)
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('自动备份')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.autoCaldavBackup!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'autoCaldavBackup', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('手动备份')
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
                  .backgroundColor(this.hoverId === 11 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 11
                }
              })
              .onClick(async () => {
                const caldavServerInfo = await getCaldavServerInfo()
                if (!caldavServerInfo.path) {
                  await promptAction.openToast({
                    message: '未配置 CalDAV 服务器，无法备份'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const res = await caldavBackupTable(this.context)
                this.dialogControllerProgress.close()
                if (res !== 'fail') {
                  await promptAction.openToast({
                    message: '备份成功'
                  })
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('恢复')
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
                  .backgroundColor(this.hoverId === 12 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 12
                }
              })
              .onClick(async () => {
                const caldavServerInfo = await getCaldavServerInfo()
                if (!caldavServerInfo.path) {
                  await promptAction.openToast({
                    message: '未配置 CalDAV 服务器，无法恢复'
                  })
                  return
                }
                this.dialogControllerProgress.open()
                const filestring = await this.getCaldavBackup()
                this.dialogControllerProgress.close()
                if (filestring !== 'fail') {
                  let conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_IGNORE
                  if (this.index === 1) {
                    conflictResolution = relationalStore.ConflictResolution.ON_CONFLICT_REPLACE
                  }
                  const res = await importTodo(this.context, JSON.stringify({
                    encrypted: false,
                    data: icsparse(filestring)
                  }), conflictResolution)
                  if (res === 'success') {
                    await promptAction.openToast({
                      message: '恢复成功'
                    })
                  }
                }
              })

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('删除备份')
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
                  .backgroundColor(this.hoverId === 13 ? $r('sys.color.interactive_hover') :
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
                  this.hoverId = 13
                }
              })
              .onClick(async () => {
                const promptAction = this.UIContext.getPromptAction()
                const caldavServerInfo = await getCaldavServerInfo()
                if (!caldavServerInfo.path) {
                  await promptAction.openToast({
                    message: '未配置 CalDAV 服务器，无法删除'
                  })
                  return
                }
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '删除成功后无法恢复，确定删除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '确定',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.dialogControllerProgress.open()
                  const res = await this.deleteCaldavBackup()
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                }
              })
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
        })

        ListItem() {
          Column() {
            Text('暂停自动备份')
              .fontColor($r('sys.color.font_secondary'))
              .fontSize($r('sys.float.ohos_id_text_size_body2'))
              .fontWeight(FontWeight.Medium)
              .margin({
                bottom: 6,
                left: 12,
                right: 12
              })
            Column() {
              Row() {
                Text('电池电量低')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pauseAutoBackupWhenLowBatteryCapacityLevel!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenLowBatteryCapacityLevel',
                      isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)

              Divider()
                .padding({
                  left: 12,
                  right: 12
                })
              Row() {
                Text('系统开启 (超级) 省电模式')
                  .fontWeight(FontWeight.Medium)
                  .layoutWeight(1)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                Toggle({
                  type: ToggleType.Switch,
                  isOn: this.pauseAutoBackupWhenPowerSave!!
                })
                  .onChange(isOn => {
                    setFlushPreference(this.context, 'dataSetting', 'pauseAutoBackupWhenPowerSave', isOn)
                  })
              }
              .borderRadius(12)
              .padding(12)
            }
            .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
            .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
            .padding($r('sys.float.ohos_id_corner_radius_mark'))
          }
          .alignItems(HorizontalAlign.Start)
        }
        .margin({
          top: $r('sys.float.ohos_id_elements_margin_vertical_l')
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
          mainTitle: '数据备份与恢复'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      this.context.eventHub.on('refreshDataBackupRecovery', async () => {
        await this.getSetting()
      })
      await this.getSetting()
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshDataBackupRecovery')
    })
  }
}