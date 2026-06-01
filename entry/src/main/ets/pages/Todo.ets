import { common } from '@kit.AbilityKit'
import { FunctionComponent } from '@kit.AgentFrameworkKit'
import { uniformTypeDescriptor } from '@kit.ArkData'
import { uri } from '@kit.ArkTS'
import { LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { netBoost } from '@kit.NetworkBoostKit'
import { rcp } from '@kit.RemoteCommunicationKit'
import { generateBarcode, scanCore } from '@kit.ScanKit'
import { harmonyShare, systemShare } from '@kit.ShareKit'
import { hdsEffect } from '@kit.UIDesignKit'
import { getTeamAccountList } from '../common/Account'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { completeTodo, deleteCloudBackup, deleteTodo, setCloudBackup } from '../common/Datachange'
import { getCurrentTimePersonalTodoList, Todo } from '../common/Dataget'
import { TodoItem } from '../common/Dataimport'
import { write } from '../common/File'
import { icsstringify } from '../common/Ics'
import { getPreferType } from '../common/Prefertype'
import { deleteQuickBarTodo, getQuickBarTodoIdList, setQuickBarTodo, syncQuickBarTodo } from '../common/Quickbar'
import { teamRequest } from '../common/Request'
import { getDateStringFromTimeStamp, getDateTimeStringFromTimeStamp, getSizeString } from '../common/Stringformat'
import { autoSyncTable, autoBackupTable } from '../common/Table'
import NewTodo from './Newtodo'
import TodoInfo from './Todoinfo'
import UpdateTodo from './Updatetodo'

@ComponentV2
export default struct TodoPage {
  @Provider() isShowNewSheet: boolean = false
  @Provider() isShowUpdateSheet: boolean = false
  @Local isShowInfoSheet: boolean = false
  @Local preferType: number = 1
  @Local todoArray: Todo[] = []
  @Local loading: boolean = false
  @Local enableCloudBackup: boolean = false
  @Local teamId: string = ''
  @Local teamNameArray: string[] = []
  @Local teamIndex: number = 0
  @Local teamValue: string = '个人'
  @Local currentTime: number = -1
  @Local timeStamp: number = Date.now()
  @Local contentKeyword: string = ''
  @Local tag: string[] = []
  @Local tags: string[] = []
  @Local multipleSelect: boolean = false
  @Local multipleSelectArray: Todo[] = []
  @Local hoverId: number = -1
  @Local buttonHoverId: number = -1
  @Local quickBarTodoIdArray: string[] = []
  @Local type: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  todoId = ''
  teamIdArray: string[] = []
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  getDateFromTimeStamp(timeStamp: number) {
    const date = new Date(timeStamp)
    return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0)
  }

  async shareTodo(todoArray: Todo[]) {
    const todos: TodoItem[] = []
    todoArray.forEach(item => {
      todos.push({
        id: item.id,
        content: item.content,
        priority: item.priority,
        startTime: item.startTime,
        endTime: item.endTime,
        duration: item.duration,
        recurrenceRule: item.recurrenceRule,
        excludeTime: item.excludeTime,
        tag: item.tag,
        dependency: item.dependency,
        location: item.location,
        action: item.action,
        bz: item.bz,
        recentCompletedTime: -1,
        updateTime: item.updateTime,
        cloudBackupTime: []
      })
    })
    const promptAction = this.UIContext.getPromptAction()
    const data = await promptAction.showActionMenu({
      title: '选择分享方式',
      buttons: [
        {
          text: '系统分享',
          color: $r('sys.color.font_primary')
        },
        {
          text: '碰一碰 / 隔空传送 (txt)',
          color: $r('sys.color.font_primary')
        },
        {
          text: '碰一碰 / 隔空传送 (ics)',
          color: $r('sys.color.font_primary')
        },
        {
          text: '链接',
          color: $r('sys.color.font_primary')
        },
        {
          text: '二维码',
          color: $r('sys.color.font_primary')
        }
      ]
    })
    if (data.index === 0) {
      const vcsPath = this.context.tempDir + '/todo.vcs'
      const icsPath = this.context.tempDir + '/todo.ics'
      const txtPath = this.context.tempDir + '/todo.txt'
      const ics = icsstringify(todos)
      await write(vcsPath, ics)
      await write(icsPath, ics)
      await write(txtPath, JSON.stringify(todos))
      const shareData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.VCS,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        label: '日历日程 (.vcs)',
        description: getSizeString(fileIo.statSync(vcsPath).size),
        uri: fileUri.getUriFromPath(vcsPath)
      })
      shareData.addRecord({
        utd: uniformTypeDescriptor.UniformDataType.ICS,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        label: '日历日程 (.ics)',
        description: getSizeString(fileIo.statSync(icsPath).size),
        uri: fileUri.getUriFromPath(icsPath)
      })
      shareData.addRecord({
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        description: getSizeString(fileIo.statSync(txtPath).size),
        uri: fileUri.getUriFromPath(txtPath)
      })
      const shareController = new systemShare.ShareController(shareData)
      await shareController.show(this.context, {})
    }
    if (data.index === 1) {
      const filePath = this.context.tempDir + '/todo.txt'
      await write(filePath, JSON.stringify(todos))
      const shareData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.PLAIN_TEXT,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        description: getSizeString(fileIo.statSync(filePath).size),
        uri: fileUri.getUriFromPath(filePath)
      })
      harmonyShare.on('knockShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      harmonyShare.on('gesturesShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      await promptAction.showDialog({
        title: '提示',
        message: '碰一碰/隔空传送邻近设备即可分享，关闭此弹窗后停止分享',
        buttons: [
          {
            text: '关闭',
            color: $r('sys.color.warning')
          }
        ],
        onDidDisappear: async () => {
          await fileIo.unlink(filePath)
          harmonyShare.off('knockShare')
          harmonyShare.off('gesturesShare')
        }
      })
    }
    if (data.index === 2) {
      const filePath = this.context.tempDir + '/todo.ics'
      await write(filePath, icsstringify(todos))
      const shareData = new systemShare.SharedData({
        utd: uniformTypeDescriptor.UniformDataType.ICS,
        title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
        description: getSizeString(fileIo.statSync(filePath).size),
        uri: fileUri.getUriFromPath(filePath)
      })
      harmonyShare.on('knockShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      harmonyShare.on('gesturesShare', async (sharableTarget) => {
        await sharableTarget.share(shareData)
      })
      await promptAction.showDialog({
        title: '提示',
        message: '碰一碰/隔空传送邻近设备即可分享，关闭此弹窗后停止分享',
        buttons: [
          {
            text: '关闭',
            color: $r('sys.color.warning')
          }
        ],
        onDidDisappear: async () => {
          await fileIo.unlink(filePath)
          harmonyShare.off('knockShare')
          harmonyShare.off('gesturesShare')
        }
      })
    }
    if (data.index === 3 || data.index === 4) {
      const urires = new uri.URI('https://www.zhangls2512.cn/product/todo')
      const url = urires.addQueryValue('share', JSON.stringify(todos)).toString()
      if (data.index === 3) {
        const shareData = new systemShare.SharedData({
          utd: uniformTypeDescriptor.UniformDataType.HYPERLINK,
          title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
          content: url
        })
        const shareController = new systemShare.ShareController(shareData)
        await shareController.show(this.context, {})
      }
      if (data.index === 4) {
        const qrcodePath = this.context.tempDir + '/todoqrcode.png'
        let qrcodeUri = ''
        try {
          const qrcodePixelMap = await generateBarcode.createBarcode(url, {
            scanType: scanCore.ScanType.QR_CODE,
            width: 200,
            height: 200
          })
          const qrcodeFile = fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
          const imagePacker = image.createImagePacker()
          await imagePacker.packToFile(qrcodePixelMap, qrcodeFile.fd, {
            format: 'image/png',
            quality: 100
          })
          await imagePacker.release()
          await qrcodePixelMap.release()
          fileIo.closeSync(qrcodeFile)
          const qrcodeFileUri = fileUri.getUriFromPath(qrcodePath)
          qrcodeUri = qrcodeFileUri
        } catch {
          const qrcodeFile = fileIo.openSync(qrcodePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY)
          const qrcodeFileStream = fileIo.fdopenStreamSync(qrcodeFile.fd, 'w+')
          netBoost.setSceneDesc({
            scene: 'download',
            sceneEvent: netBoost.SceneEvent.SCENE_EVENT_ENTER
          })
          const session = rcp.createSession({
            requestConfiguration: {
              tracing: {
                httpEventsHandler: {
                  onDataReceive: async (incomingData) => {
                    await qrcodeFileStream.write(incomingData)
                  },
                  onDataEnd: () => {
                    this.dialogControllerProgress.close()
                    session.close()
                    netBoost.setSceneDesc({
                      scene: 'download',
                      sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
                    })
                    qrcodeFileStream.closeSync()
                  }
                }
              },
              security: {
                tlsRange: {
                  min: 'TlsV1.2'
                }
              }
            }
          })
          this.dialogControllerProgress.open()
          try {
            const response = await session.get('https://uapis.cn/api/v1/image/qrcode?text=' + encodeURIComponent(url))
            session.close()
            this.dialogControllerProgress.close()
            if (response.statusCode >= 200 && response.statusCode < 300) {
              qrcodeUri = fileUri.getUriFromPath(qrcodePath)
            } else {
              await promptAction.openToast({
                message: 'HTTP 请求失败，状态码：' + response.statusCode
              })
            }
          } catch (err) {
            this.dialogControllerProgress.close()
            session.close()
            netBoost.setSceneDesc({
              scene: 'download',
              sceneEvent: netBoost.SceneEvent.SCENE_EVENT_LEAVE
            })
            qrcodeFileStream.closeSync()
            await promptAction.openToast({
              message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
            })
          }
        }
        if (qrcodeUri) {
          const shareData = new systemShare.SharedData({
            utd: uniformTypeDescriptor.UniformDataType.IMAGE,
            title: todos.length > 1 ? '“' + todos[0].content + '”等 ' + todos.length + ' 个待办' : todos[0].content,
            thumbnailUri: qrcodeUri,
            uri: qrcodeUri
          })
          const shareController = new systemShare.ShareController(shareData)
          await shareController.show(this.context, {})
        }
      }
    }
  }

  @Builder
  MenuBuilder(item: Todo) {
    Menu() {
      if (this.multipleSelect) {
        MenuItem({
          startIcon: $r('app.media.multipleselect'),
          content: '取消多选'
        })
          .onClick(() => {
            this.multipleSelect = false
            this.multipleSelectArray = []
          })
      }
      if (!this.multipleSelect) {
        if (!this.teamId) {
          MenuItem({
            startIcon: $r('app.media.multipleselect'),
            content: '多选'
          })
            .onClick(() => {
              this.multipleSelect = true
              this.multipleSelectArray.push(item)
            })
        }
        if (!this.teamId && deviceInfo.deviceType === '2in1') {
          if (!this.quickBarTodoIdArray.includes(item.id)) {
            MenuItem({
              startIcon: $r('app.media.addcircle'),
              content: '添加至快捷栏'
            })
              .onClick(async () => {
                await setQuickBarTodo(this.context, item.id, item.content)
                await syncQuickBarTodo(this.context)
                this.quickBarTodoIdArray = await getQuickBarTodoIdList(this.context)
                if (this.quickBarTodoIdArray.includes(item.id)) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.openToast({
                    message: '添加成功'
                  })
                }
              })
          }
          if (this.quickBarTodoIdArray.includes(item.id)) {
            MenuItem({
              startIcon: $r('app.media.removecircle'),
              content: '从快捷栏移除'
            })
              .onClick(async () => {
                await deleteQuickBarTodo(this.context, item.id)
                await syncQuickBarTodo(this.context)
                this.quickBarTodoIdArray = await getQuickBarTodoIdList(this.context)
                if (!this.quickBarTodoIdArray.includes(item.id)) {
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.openToast({
                    message: '移除成功'
                  })
                }
              })
          }
        }
        MenuItem({
          startIcon: $r('app.media.info'),
          content: '详情'
        })
          .onClick(() => {
            this.todoId = item.id
            this.isShowInfoSheet = true
          })
        if (!this.teamId) {
          MenuItem({
            startIcon: $r('app.media.share'),
            content: '分享'
          })
            .onClick(async () => {
              await this.shareTodo([item])
            })
        }
        MenuItem({
          startIcon: $r('app.media.edit'),
          content: '修改'
        })
          .onClick(() => {
            this.todoId = item.id
            this.isShowUpdateSheet = true
          })
        if (!this.teamId || this.type === 'create') {
          MenuItem({
            startIcon: $r('app.media.delete'),
            content: '删除'
          })
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              if (!this.teamId) {
                if (!item.recurrenceRule) {
                  const data = await promptAction.showDialog({
                    title: '提示',
                    message: '删除成功后无法恢复，确定删除？',
                    buttons: [
                      {
                        text: '取消',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '删除',
                        color: $r('sys.color.warning')
                      }
                    ]
                  })
                  if (data.index === 1) {
                    this.dialogControllerProgress.open()
                    await deleteTodo(this.context, item.id)
                    this.dialogControllerProgress.close()
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                }
                if (item.recurrenceRule) {
                  const data = await promptAction.showActionMenu({
                    title: '删除模式',
                    buttons: [
                      {
                        text: '仅限此待办',
                        color: $r('sys.color.font_primary')
                      },
                      {
                        text: '所有重复待办',
                        color: $r('sys.color.font_primary')
                      }
                    ]
                  })
                  if (data.index === 0) {
                    this.dialogControllerProgress.open()
                    await deleteTodo(this.context, item.id, true, item.excludeTime.concat([item.startTime]))
                    this.dialogControllerProgress.close()
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                  if (data.index === 1) {
                    this.dialogControllerProgress.open()
                    await deleteTodo(this.context, item.id)
                    this.dialogControllerProgress.close()
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                }
                this.loading = true
              }
              if (this.teamId) {
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '删除成功后无法恢复，确定删除？',
                  buttons: [
                    {
                      text: '取消',
                      color: $r('sys.color.font_primary')
                    },
                    {
                      text: '删除',
                      color: $r('sys.color.warning')
                    }
                  ]
                })
                if (data.index === 1) {
                  this.dialogControllerProgress.open()
                  const res = await teamRequest(this.context, this.teamId, '/deleteTodo', {
                    id: item.id
                  })
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    this.loading = true
                    await promptAction.openToast({
                      message: '删除成功'
                    })
                  }
                }
              }
            })
        }
        if (!this.teamId) {
          if (this.enableCloudBackup && !item.isCloudBackup) {
            MenuItem({
              startIcon: $r('app.media.cloud'),
              content: '云备份'
            })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                await setCloudBackup(this.context, {
                  id: item.id,
                  content: JSON.stringify({
                    content: item.content,
                    priority: item.priority,
                    startTime: item.startTime,
                    endTime: item.endTime,
                    duration: item.duration,
                    recurrenceRule: item.recurrenceRule,
                    excludeTime: item.excludeTime,
                    tag: item.tag,
                    dependency: item.dependency,
                    location: item.location,
                    action: item.action,
                    bz: item.bz,
                    recentCompletedTime: item.recentCompletedTime,
                    updateTime: item.updateTime,
                    cloudBackupTime: item.cloudBackupTime
                  })
                })
                this.dialogControllerProgress.close()
                await promptAction.openToast({
                  message: '云备份成功'
                })
                this.loading = true
              })
          }
          if (this.enableCloudBackup && item.isCloudBackup) {
            MenuItem({
              startIcon: $r('app.media.clouddelete'),
              content: '取消云备份'
            })
              .onClick(async () => {
                this.dialogControllerProgress.open()
                await deleteCloudBackup(this.context, item.id)
                this.dialogControllerProgress.close()
                await promptAction.openToast({
                  message: '取消云备份成功'
                })
                this.loading = true
              })
          }
        }
      }
    }
  }

  @Builder
  NewSheetBuilder() {
    NewTodo({
      teamId: this.teamId
    })
  }

  @Builder
  InfoSheetBuilder() {
    TodoInfo({
      todoId: this.todoId,
      teamId: this.teamId
    })
  }

  @Builder
  UpdateSheetBuilder() {
    UpdateTodo({
      todoId: this.todoId,
      teamId: this.teamId
    })
  }

  build() {
    Scroll() {
      Column() {
        if (this.multipleSelect) {
          Row() {
            Column() {
              Image($r('app.media.cancel'))
            }
            .borderRadius(20)
            .height(40)
            .keyboardShortcut(FunctionKey.ESC, [])
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(() => {
              this.multipleSelect = false
              this.multipleSelectArray = []
            })

            Text('已选择 ' + this.multipleSelectArray.length + ' 项')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Column() {
              Image($r('app.media.share'))
            }
            .borderRadius(20)
            .height(40)
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(async () => {
              await this.shareTodo(this.multipleSelectArray)
              this.multipleSelect = false
              this.multipleSelectArray = []
            })

            Column() {
              Image($r('app.media.delete'))
            }
            .borderRadius(20)
            .height(40)
            .keyboardShortcut('D', [ModifierKey.CTRL])
            .margin({
              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
            })
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(async () => {
              const promptAction = this.UIContext.getPromptAction()
              if (this.multipleSelectArray.length === 0) {
                await promptAction.openToast({
                  message: '未选择'
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
                    text: '删除',
                    color: $r('sys.color.warning')
                  }
                ]
              })
              if (data.index === 1) {
                for (let i = 0; i < this.multipleSelectArray.length; i++) {
                  const dialogControllerProgress = new CustomDialogController({
                    builder: LoadingDialog({
                      content: '批量删除中，进度：' + (i + 1) + '/' + this.multipleSelectArray.length
                    })
                  })
                  dialogControllerProgress.open()
                  await deleteTodo(this.context, this.multipleSelectArray[i].id, false)
                  dialogControllerProgress.close()
                  await promptAction.openToast({
                    message: '删除成功'
                  })
                }
                this.loading = true
                await autoSyncTable(this.context)
                await autoBackupTable(this.context)
              }
            })

            Column() {
              Image($r('app.media.cloud'))
            }
            .borderRadius(20)
            .height(40)
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor($r('sys.color.interactive_hover'))
              },
              pressed: {
                .backgroundColor($r('sys.color.interactive_pressed'))
              }
            })
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
              })
              .buildEffect())
            .width(40)
            .onClick(async () => {
              if (this.multipleSelectArray.length === 0) {
                await promptAction.openToast({
                  message: '未选择'
                })
                return
              }
              for (let i = 0; i < this.multipleSelectArray.length; i++) {
                const dialogControllerProgress = new CustomDialogController({
                  builder: LoadingDialog({
                    content: '批量云备份中，进度：' + (i + 1) + '/' + this.multipleSelectArray.length
                  })
                })
                dialogControllerProgress.open()
                await setCloudBackup(this.context, {
                  id: this.multipleSelectArray[i].id,
                  content: JSON.stringify({
                    content: this.multipleSelectArray[i].content,
                    priority: this.multipleSelectArray[i].priority,
                    startTime: this.multipleSelectArray[i].startTime,
                    endTime: this.multipleSelectArray[i].endTime,
                    duration: this.multipleSelectArray[i].duration,
                    recurrenceRule: this.multipleSelectArray[i].recurrenceRule,
                    excludeTime: this.multipleSelectArray[i].excludeTime,
                    tag: this.multipleSelectArray[i].tag,
                    dependency: this.multipleSelectArray[i].dependency,
                    location: this.multipleSelectArray[i].location,
                    action: this.multipleSelectArray[i].action,
                    bz: this.multipleSelectArray[i].bz,
                    recentCompletedTime: this.multipleSelectArray[i].recentCompletedTime,
                    updateTime: this.multipleSelectArray[i].updateTime,
                    cloudBackupTime: this.multipleSelectArray[i].cloudBackupTime
                  })
                }, false)
                dialogControllerProgress.close()
                await promptAction.openToast({
                  message: '云备份成功'
                })
              }
              this.loading = true
              await autoSyncTable(this.context)
              await autoBackupTable(this.context)
            })
          }
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
        }
        if (!this.multipleSelect) {
          Row() {
            Column() {
              Image($r('app.media.new_white'))
            }
            .borderRadius(20)
            .height(40)
            .keyboardShortcut('N', [ModifierKey.CTRL, ModifierKey.SHIFT])
            .padding(11)
            .stateStyles({
              normal: {
                .backgroundColor(this.buttonHoverId === 0 ? '#0754EB' : $r('sys.color.background_emphasize'))
              },
              pressed: {
                .backgroundColor('#0A50DE')
              }
            })
            .width(40)
            .onHover(isHover => {
              if (!isHover) {
                this.buttonHoverId = -1
              }
              if (isHover) {
                this.buttonHoverId = 0
              }
            })
            .onClick(() => {
              this.isShowNewSheet = true
            })
            .bindSheet(this.isShowNewSheet!!, this.NewSheetBuilder(), {
              height: SheetSize.FIT_CONTENT,
              preferType: this.preferType,
              title: {
                title: '新增待办'
              },
              onDisappear: () => {
                this.loading = true
              },
              onWillDismiss: async (DismissSheetAction) => {
                const promptAction = this.UIContext.getPromptAction()
                const data = await promptAction.showDialog({
                  title: '提示',
                  message: '数据尚未保存，确定退出？',
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
                if (data.index === 1) {
                  DismissSheetAction.dismiss()
                }
              }
            })

            Blank()
            Text(getDateStringFromTimeStamp(this.currentTime))
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .onClick(() => {
                this.UIContext.showDatePickerDialog({
                  selected: this.getDateFromTimeStamp(this.currentTime),
                  onDateAccept: (value) => {
                    this.currentTime =
                      new Date(value.getFullYear(), value.getMonth(), value.getDate(), 0, 0, 0).getTime()
                    this.loading = true
                  }
                })
              })
            if (deviceInfo.deviceType !== '2in1') {
              Column() {
                FunctionComponent({
                  agentId: 'agent5e4f855080cf442ebf578126e9117b4a',
                  onError: () => {
                  }
                })
              }
              .borderRadius(20)
              .height(40)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.SOFT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT
                })
                .buildEffect())
              .width(40)
            }
            Select(this.teamNameArray.map((item): SelectOption => {
              return {
                value: item
              }
            }))
              .selected(this.teamIndex!!)
              .value(this.teamValue!!)
              .onSelect(index => {
                if (index === 0) {
                  this.type = ''
                  this.teamId = ''
                } else {
                  if (!this.teamId) {
                    this.type = 'complete'
                  }
                  this.teamId = this.teamIdArray[this.teamIndex - 1]
                }
                this.loading = true
              })
          }
          .width('100%')

          Search({
            placeholder: '请输入内容关键词',
            value: this.contentKeyword!!
          })
            .searchButton('搜索')
            .onSubmit(() => {
              this.todoArray = this.todoArray.filter(item => item.content.includes(this.contentKeyword) &&
                this.tag.every(tagItem => item.tag.includes(tagItem)))
            })
          Scroll() {
            Row() {
              ForEach(this.tags, (item: string, index) => {
                if (!this.tag.includes(item)) {
                  Column() {
                    Row() {
                      Text(item)
                        .enableAutoSpacing(true)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.tag.push(item)
                      this.todoArray = this.todoArray.filter(item => item.content.includes(this.contentKeyword) &&
                        this.tag.every(tagItem => item.tag.includes(tagItem)))
                    })
                  }
                  .backgroundColor($r('sys.color.comp_background_primary'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.tags.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
                if (this.tag.includes(item)) {
                  Column() {
                    Row() {
                      Text(item)
                        .enableAutoSpacing(true)
                        .fontColor(Color.White)
                        .fontWeight(FontWeight.Medium)
                    }
                    .padding(12)
                    .onClick(() => {
                      this.tag.splice(this.tag.indexOf(item), 1)
                      this.todoArray = this.todoArray.filter(item => item.content.includes(this.contentKeyword) &&
                        this.tag.every(tagItem => item.tag.includes(tagItem)))
                    })
                  }
                  .backgroundColor($r('sys.color.background_emphasize'))
                  .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                  .margin({
                    right: index === this.tags.length - 1 ? 0 : $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                }
              })
            }
          }
          .edgeEffect(EdgeEffect.Spring)
          .margin({
            bottom: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
        }
        if (this.todoArray.length === 0 && !this.loading) {
          Text('无数据')
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .textAlign(TextAlign.Center)
            .width('100%')
        }
        Refresh({
          refreshing: $$this.loading
        }) {
          List() {
            ForEach(this.todoArray, (item: Todo, index) => {
              ListItem() {
                Column() {
                  Row() {
                    if (this.multipleSelect) {
                      Toggle({
                        type: ToggleType.Checkbox,
                        isOn: this.multipleSelectArray.some(selectItem => selectItem.id === item.id)
                      })
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onChange(isOn => {
                          if (!isOn) {
                            this.multipleSelectArray.splice(
                              this.multipleSelectArray.findIndex(selectItem => selectItem.id ===
                                item.id), 1)
                          }
                          if (isOn) {
                            this.multipleSelectArray.push(item)
                          }
                        })
                    }
                    if (!this.multipleSelect) {
                      Toggle({
                        type: ToggleType.Checkbox,
                        isOn: item.isCompleted
                      })
                        .enabled(item.canCompleted)
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .onChange(async (isOn) => {
                          if (!this.teamId) {
                            this.dialogControllerProgress.open()
                            await completeTodo(this.context, item.id, isOn)
                            this.dialogControllerProgress.close()
                            this.loading = true
                          }
                          if (item.teamId) {
                            const res = await teamRequest(this.context, this.teamId, '/completeTodo', {
                              id: item.id
                            })
                            if (res !== 'fail') {
                              this.loading = true
                            }
                          }
                        })
                    }
                    if (item.isCloudBackup) {
                      Image($r('app.media.cloud'))
                        .margin({
                          right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                        })
                        .width('5%')
                    }
                    Column() {
                      if (!item.isCompleted) {
                        Text(item.content)
                          .enableAutoSpacing(true)
                          .fontColor(
                            (item.endTime !== -1 && item.endTime < this.timeStamp) ? $r('sys.color.warning') : '')
                          .fontWeight(FontWeight.Bold)
                      }
                      if (item.isCompleted) {
                        Text(item.content)
                          .decoration({
                            type: TextDecorationType.LineThrough,
                            color: $r('sys.color.font_tertiary')
                          })
                          .enableAutoSpacing(true)
                          .fontColor($r('sys.color.font_tertiary'))
                          .fontWeight(FontWeight.Bold)
                      }
                      Row() {
                        Text('开始时间')
                          .fontWeight(FontWeight.Medium)
                          .margin({
                            right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                          })
                        Text(getDateTimeStringFromTimeStamp(item.startTime))
                          .enableAutoSpacing(true)
                          .layoutWeight(1)
                      }
                      .margin({
                        top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                      })

                      if (item.endTime !== -1) {
                        Row() {
                          Text('结束时间')
                            .fontWeight(FontWeight.Medium)
                            .margin({
                              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                            })
                          Text(getDateTimeStringFromTimeStamp(item.endTime))
                            .enableAutoSpacing(true)
                            .layoutWeight(1)
                        }
                        .margin({
                          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                        })
                      }
                      if (item.location.location) {
                        Row() {
                          Text('地点')
                            .fontWeight(FontWeight.Medium)
                            .margin({
                              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                            })
                          Text(item.location.location)
                            .enableAutoSpacing(true)
                            .layoutWeight(1)
                        }
                        .margin({
                          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                        })
                      }
                      if (item.tag.length > 0) {
                        Row() {
                          Text('标签')
                            .fontWeight(FontWeight.Medium)
                            .margin({
                              right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                            })
                          Text(item.tag.join('、'))
                            .enableAutoSpacing(true)
                            .layoutWeight(1)
                        }
                        .margin({
                          top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                        })
                      }
                    }
                    .alignItems(HorizontalAlign.Start)
                    .layoutWeight(1)
                  }
                  .borderRadius(12)
                  .padding(12)
                  .stateStyles({
                    normal: {
                      .backgroundColor(this.hoverId === index ? $r('sys.color.interactive_hover') :
                        $r('sys.color.comp_background_primary'))
                    },
                    pressed: {
                      .backgroundColor($r('sys.color.comp_background_secondary'))
                    }
                  })
                  .onHover(isHover => {
                    if (!isHover) {
                      this.hoverId = -1
                    }
                    if (isHover) {
                      this.hoverId = index
                    }
                  })
                  .bindContextMenu(this.MenuBuilder(item), ResponseType.LongPress, {
                    hapticFeedbackMode: HapticFeedbackMode.AUTO
                  })
                  .bindContextMenu(this.MenuBuilder(item), ResponseType.RightClick, {
                    hapticFeedbackMode: HapticFeedbackMode.AUTO
                  })
                }
                .backgroundColor($r('sys.color.comp_background_primary'))
                .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
                .padding($r('sys.float.ohos_id_corner_radius_mark'))
              }
              .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
              .selected(this.multipleSelectArray.some(selectItem => selectItem.id === item.id))
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onSelect(isSelected => {
                if (!isSelected) {
                  this.multipleSelectArray = this.multipleSelectArray.filter(selectItem => selectItem.id !== item.id)
                }
                if (isSelected) {
                  this.multipleSelect = true
                  if (!this.multipleSelectArray.find(selectItem => selectItem.id === item.id)) {
                    this.multipleSelectArray.push(item)
                  }
                }
              })
            })
            ListItem()
              .margin({
                bottom: 80
              })
          }
          .height('100%')
          .lanes({
            fillType: PresetFillType.BREAKPOINT_DEFAULT
          }, $r('sys.float.ohos_id_elements_margin_horizontal_m'))
          .multiSelectable(true)
        }
        .keyboardShortcut('R', [ModifierKey.CTRL], () => {
          this.loading = true
        })
        .layoutWeight(1)
        .onRefreshing(async () => {
          this.tag = []
          this.tags = []
          this.multipleSelect = false
          this.multipleSelectArray = []
          this.todoArray = []
          if (!this.teamId) {
            this.todoArray = await getCurrentTimePersonalTodoList(this.context, this.currentTime)
            this.timeStamp = Date.now()
            const allTagArray: string[] = []
            this.todoArray.forEach(item => {
              item.tag.forEach(tagItem => {
                if (!allTagArray.includes(tagItem)) {
                  allTagArray.push(tagItem)
                }
              })
            })
            this.tags = allTagArray.sort((a, b) => a.localeCompare(b))
            if (deviceInfo.deviceType === '2in1') {
              await syncQuickBarTodo(this.context)
              this.quickBarTodoIdArray = await getQuickBarTodoIdList(this.context)
            }
          }
          if (this.teamId) {
            this.dialogControllerProgress.open()
            const res = await teamRequest(this.context, this.teamId, '/getTodoList', {
              type: this.type,
              currentTime: this.currentTime
            })
            this.dialogControllerProgress.close()
            if (res !== 'fail') {
              this.todoArray = JSON.parse(res).data
            }
          }
          this.loading = false
        })
        .bindSheet(this.isShowInfoSheet!!, this.InfoSheetBuilder(), {
          height: SheetSize.FIT_CONTENT,
          preferType: this.preferType,
          title: {
            title: '待办详情'
          }
        })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding({
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      top: this.preferType === 0 ? 0 : $r('sys.float.ohos_id_default_padding_top')
    })
    .onAppear(async () => {
      this.preferType = getPreferType(this.UIContext)
      this.context.eventHub.on('refreshTodo', async () => {
        const teamAccountArray = await getTeamAccountList()
        this.teamIdArray = teamAccountArray.map(item => item.teamId)
        this.teamNameArray = ['个人'].concat(teamAccountArray.map(item => item.teamName))
        const index = this.teamNameArray.indexOf(this.teamValue)
        if (index === -1) {
          this.teamId = ''
          this.teamIndex = 0
          this.teamValue = '个人'
        }
        this.loading = true
        if (!this.teamId) {
          this.enableCloudBackup = false
          const cloudServiceStatus = await getCloudServiceStatus(this.context)
          if (cloudServiceStatus && getKeyAlg()) {
            this.enableCloudBackup = true
          }
        }
      })
      const currentDate = new Date()
      this.currentTime =
        new Date(currentDate.getFullYear(), currentDate.getMonth(), currentDate.getDate(), 0, 0, 0).getTime()
      const teamAccountArray = await getTeamAccountList()
      this.teamIdArray = teamAccountArray.map(item => item.teamId)
      this.teamNameArray = ['个人'].concat(teamAccountArray.map(item => item.teamName))
      this.loading = true
      const cloudServiceStatus = await getCloudServiceStatus(this.context)
      if (cloudServiceStatus && getKeyAlg()) {
        this.enableCloudBackup = true
      }
    })
    .onDisAppear(() => {
      this.context.eventHub.off('refreshTodo')
    })
    .bindSheet(this.isShowUpdateSheet!!, this.UpdateSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      preferType: this.preferType,
      title: {
        title: '修改待办'
      },
      onDisappear: () => {
        this.loading = true
      },
      onWillDismiss: async (DismissSheetAction) => {
        const promptAction = this.UIContext.getPromptAction()
        const data = await promptAction.showDialog({
          title: '提示',
          message: '数据尚未保存，确定退出？',
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
        if (data.index === 1) {
          DismissSheetAction.dismiss()
        }
      }
    })
  }
}