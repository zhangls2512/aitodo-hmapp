import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { deviceInfo } from '@kit.BasicServicesKit'
import { camera, cameraPicker } from '@kit.CameraKit'
import { fileIo, fileShare, picker } from '@kit.CoreFileKit'
import { speechRecognizer } from '@kit.CoreSpeechKit'
import { textRecognition } from '@kit.CoreVisionKit'
import { image } from '@kit.ImageKit'
import { sceneMap } from '@kit.MapKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { EntityType, textProcessing } from '@kit.NaturalLanguageKit'
import {
  CollaborationServiceFilter,
  CollaborationServiceStateDialog,
  createCollaborationServiceMenuItems
} from '@kit.ServiceCollaborationKit'
import { hdsEffect } from '@kit.UIDesignKit'
import getCloudServiceStatus from '../common/Cloudservice'
import { getKeyAlg } from '../common/Crypto'
import { getCustomFreqList } from '../common/Customfreq'
import { Action, newTodo } from '../common/Datachange'
import { icsTimeStringToTimeStamp, timeStampToIcsTimeString } from '../common/Ics'
import openLink from '../common/Openlink'
import { checkPermission } from '../common/Permission'
import { getFlushPreference } from '../common/Preference'
import { isProxyReminderEnabled } from '../common/Proxyreminder'
import { getDateTimeStringFromTimeStamp } from '../common/Stringformat'
import { OpenAppByTypeValue } from './Todoinfo'

interface DateTime {
  startTimestamp: number,
  endTimestamp: number,
  rrule: string
}

@ComponentV2
export default struct Newtodo {
  @Consumer() isShowNewSheet: boolean = false
  @Param teamId: string = ''
  @Local aiContent: string = ''
  @Local content: string = ''
  @Local priority: number = 0
  @Local startTime: number = Date.now()
  @Local remind: boolean = false
  @Local remindEnabled: boolean = true
  @Local endTime: number = -1
  @Local duration: string = '0'
  @Local recurrence: boolean = false
  @Local recurrenceFreqIndex: number = 0
  @Local recurrenceFreqValue: string = '年'
  @Local freq: SelectOption[] = []
  @Local recurrenceInterval: string = '1'
  @Local recurrenceUntil: number = -1
  @Local recurrenceCount: string = '0'
  @Local recurrenceByMonth: number[] = []
  @Local recurrenceByMonthDay: number[] = []
  @Local recurrenceByDay: string[] = []
  @Local tagArray: string[] = []
  @Local tag: string = ''
  @Local dependencyArray: string[] = []
  @Local dependency: string = ''
  @Local locationLatitude: number = -1
  @Local locationLongitude: number = -1
  @Local locationLocation: string = ''
  @Local actionArray: Action[] = []
  @Local actionTypeIndex: number = 0
  @Local actionTypeValue: string = '打开应用'
  @Local actionValue: string = ''
  @Local bz: string = ''
  @Local cloudBackup: boolean = false
  @Local allowCloudBackup: boolean = false
  @Local alertText: string = ''
  UIContext = this.getUIContext()
  context = this.UIContext.getHostContext() as common.UIAbilityContext
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '识别中...'
    })
  })
  dayMap: Record<string, string> = {
    'MO': '星期一',
    'TU': '星期二',
    'WE': '星期三',
    'TH': '星期四',
    'FR': '星期五',
    'SA': '星期六',
    'SU': '星期日'
  }
  actionTypeMap: Record<string, string> = {
    'openApp': '打开应用',
    'openAppByType': '打开指定类型应用',
    'openUrl': '打开链接',
    'openFile': '打开文件',
    'callTelephone': '拨号'
  }

  async dealWithAiContent() {
    if (this.aiContent) {
      const entity = await textProcessing.getEntity(this.aiContent, {
        entityTypes: [
          EntityType.DATETIME,
          EntityType.EMAIL,
          EntityType.EXPRESS_NO,
          EntityType.FLIGHT_NO,
          EntityType.LOCATION,
          EntityType.PHONE_NO,
          EntityType.URL
        ]
      })
      const list: Action[] = []
      entity.forEach(item => {
        if (item.type === EntityType.DATETIME) {
          const dateTime = JSON.parse(item.jsonObject) as DateTime
          if (dateTime.startTimestamp) {
            if (dateTime.startTimestamp > this.endTime && this.endTime !== -1) {
              return
            }
            this.startTime = dateTime.startTimestamp
          }
          if (dateTime.endTimestamp) {
            if (dateTime.endTimestamp < this.startTime) {
              return
            }
            this.endTime = dateTime.endTimestamp
          }
          if (!dateTime.rrule) {
            this.recurrence = false
            this.recurrenceFreqIndex = 0
            this.recurrenceFreqValue = '年'
            this.recurrenceInterval = '1'
            this.recurrenceUntil = -1
            this.recurrenceCount = '0'
            this.recurrenceByMonth = []
            this.recurrenceByMonthDay = []
            this.recurrenceByDay = []
          }
          if (dateTime.rrule) {
            this.recurrence = true
            this.recurrenceFreqIndex = 0
            this.recurrenceFreqValue = '年'
            this.recurrenceInterval = '1'
            this.recurrenceUntil = -1
            this.recurrenceCount = '0'
            this.recurrenceByMonth = []
            this.recurrenceByMonthDay = []
            this.recurrenceByDay = []
            const recurrenceRule = dateTime.rrule
            const tokens = recurrenceRule.split(';')
            const keyValues = tokens.map(item => item.split('=', 2))
            keyValues.forEach(item => {
              const key = item[0]
              const value = item[1]
              if (key === 'FREQ') {
                const index = ['YEARLY', 'MONTHLY', 'WEEKLY', 'DAILY'].indexOf(value)
                if (index !== -1) {
                  this.recurrenceFreqIndex = index
                  this.recurrenceFreqValue = this.freq[this.recurrenceFreqIndex].value as string
                }
                if (index === -1) {
                  this.recurrence = false
                }
              }
              if (key === 'INTERVAL') {
                this.recurrenceInterval = value
              }
              if (key === 'UNTIL') {
                this.recurrenceUntil = icsTimeStringToTimeStamp(value, true)
              }
              if (key === 'COUNT') {
                this.recurrenceCount = value
              }
              if (key === 'BYMONTH') {
                this.recurrenceByMonth = value.split(',').map(item => Number(item))
              }
              if (key === 'BYMONTHDAY') {
                this.recurrenceByMonthDay = value.split(',').map(item => Number(item))
              }
              if (key === 'BYDAY') {
                this.recurrenceByDay = value.split(',')
              }
            })
          }
        }
        if (item.type === EntityType.EMAIL) {
          const value: OpenAppByTypeValue = {
            type: 'mail',
            wantParam: {
              'sceneType': 1,
              'email': [encodeURI(item.text)]
            }
          }
          list.push({
            type: 'openAppByType',
            value: JSON.stringify(value)
          })
        }
        if (item.type === EntityType.EXPRESS_NO) {
          const value: OpenAppByTypeValue = {
            type: 'express',
            wantParam: {
              'sceneType': 1,
              'expressNo': item.text
            }
          }
          list.push({
            type: 'openAppByType',
            value: JSON.stringify(value)
          })
        }
        if (item.type === EntityType.FLIGHT_NO) {
          const value: OpenAppByTypeValue = {
            type: 'flight',
            wantParam: {
              'sceneType': 1,
              'flightNo': item.text
            }
          }
          list.push({
            type: 'openAppByType',
            value: JSON.stringify(value)
          })
        }
        if (item.type === EntityType.LOCATION) {
          this.locationLocation = item.text
        }
        if (item.type === EntityType.PHONE_NO) {
          list.push({
            type: 'callTelephone',
            value: item.text
          })
        }
        if (item.type === EntityType.URL) {
          list.push({
            type: 'openUrl',
            value: item.text
          })
        }
      })
      list.forEach(item => {
        if (!this.actionArray.find(actionItem => actionItem.type === item.type &&
          actionItem.value === item.value)) {
          this.actionArray.push(item)
        }
      })
    }
  }

  @Builder
  ChooseImageMenu() {
    Menu() {
      MenuItem({ content: '拍照' })
        .onClick(async () => {
          try {
            const pickerres = await cameraPicker.pick(this.context, [cameraPicker.PickerMediaType.PHOTO], {
              cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
            })
            const fileSource = fileIo.openSync(pickerres.resultUri)
            const imageSource = image.createImageSource(fileSource.fd)
            const imagePixelMap = await imageSource.createPixelMap()
            await imageSource.release()
            const initres = await textRecognition.init()
            if (initres) {
              this.dialogControllerProgress.open()
              const textrecognitionres = await textRecognition.recognizeText({
                pixelMap: imagePixelMap
              })
              await textRecognition.release()
              await imagePixelMap.release()
              this.dialogControllerProgress.close()
              this.aiContent = textrecognitionres.value
              await this.dealWithAiContent()
            }
          } catch {
          }
        })
      MenuItem({ content: '从图库中选择' })
        .onClick(async () => {
          try {
            const photoPicker = new photoAccessHelper.PhotoViewPicker()
            const pickerres = await photoPicker.select({
              MIMEType: photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,
              maxSelectNumber: 1,
              isPhotoTakingSupported: false,
              isOriginalSupported: false
            })
            const fileSource = fileIo.openSync(pickerres.photoUris[0])
            const imageSource = image.createImageSource(fileSource.fd)
            const imagePixelMap = await imageSource.createPixelMap()
            await imageSource.release()
            const initres = await textRecognition.init()
            if (initres) {
              this.dialogControllerProgress.open()
              const textrecognitionres = await textRecognition.recognizeText({
                pixelMap: imagePixelMap
              })
              await textRecognition.release()
              await imagePixelMap.release()
              this.dialogControllerProgress.close()
              this.aiContent = textrecognitionres.value
              await this.dealWithAiContent()
            }
          } catch {
          }
        })
      if (deviceInfo.deviceType !== 'phone') {
        MenuItem({
          content: '从其他设备导入',
          builder: this.SubMenu()
        })
      }
    }
  }

  @Builder
  SubMenu() {
    Menu() {
      createCollaborationServiceMenuItems([CollaborationServiceFilter.TAKE_PHOTO,
        CollaborationServiceFilter.IMAGE_PICKER], 1)
    }
  }

  build() {
    List() {
      ListItem() {
        Column() {
          CollaborationServiceStateDialog({
            async onState(stateCode: number, bufferType: string, buffer: ArrayBuffer) {
              if (stateCode !== 0) {
                await promptAction.openToast({
                  message: '发生错误，错误码：' + stateCode
                })
                return
              }
              if (bufferType !== 'general.image') {
                await promptAction.openToast({
                  message: '请导入图片'
                })
                return
              }
              const imageSource = image.createImageSource(buffer)
              const imagePixelMap = await imageSource.createPixelMap()
              await imageSource.release()
              const initres = await textRecognition.init()
              if (initres) {
                this.dialogControllerProgress.open()
                const textrecognitionres = await textRecognition.recognizeText({
                  pixelMap: imagePixelMap
                })
                await textRecognition.release()
                await imagePixelMap.release()
                this.dialogControllerProgress.close()
                this.aiContent = textrecognitionres.value
                await this.dealWithAiContent()
              }
            }
          })
          Row() {
            Button('图片识别')
              .layoutWeight(1)
              .bindMenu(this.ChooseImageMenu, {
                hapticFeedbackMode: HapticFeedbackMode.AUTO
              })
            Blank()
              .width($r('sys.float.ohos_id_elements_margin_horizontal_m'))
            Button('语音识别')
              .layoutWeight(1)
              .onClick(async () => {
                const permission = await checkPermission(this.context, this.UIContext, 'ohos.permission.MICROPHONE')
                if (permission) {
                  const asrEngine = await speechRecognizer.createEngine({
                    language: 'zh-CN',
                    online: 1
                  })
                  const sessionId = util.generateRandomUUID()
                  asrEngine.setListener({
                    onStart() {
                    },
                    onEvent() {
                    },
                    onResult: (sessionId, result) => {
                      this.aiContent = result.result
                    },
                    onComplete: async () => {
                      asrEngine.shutdown()
                      await this.dealWithAiContent()
                    },
                    async onError(sessionId, errorCode, errorMessage) {
                      if (errorCode !== 1002200007) {
                        await promptAction.openToast({
                          message: '发生错误，错误码：' + errorCode + '，错误信息：' + errorMessage
                        })
                      }
                    }
                  })
                  asrEngine.startListening({
                    sessionId: sessionId,
                    audioInfo: {
                      audioType: 'pcm',
                      sampleRate: 16000,
                      sampleBit: 16,
                      soundChannel: 1
                    },
                    extraParams: {
                      recognitionMode: 0
                    }
                  })
                  const promptAction = this.UIContext.getPromptAction()
                  await promptAction.showDialog({
                    title: '提示',
                    message: '正在录音...',
                    buttons: [
                      {
                        text: '结束录音',
                        color: $r('sys.color.warning')
                      }
                    ],
                    onDidDisappear: () => {
                      asrEngine.finish(sessionId)
                    }
                  })
                }
              })
          }

          TextArea({
            placeholder: '输入文本，智能识别其中的日期时间、电子邮件、快递单号、航班号、地址、手机号、网址并填入',
            text: this.aiContent!!
          })
            .defaultFocus(true)
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .maxLength(1000)
            .showCounter(true)
            .visualEffect(new hdsEffect.HdsEffectBuilder()
              .pointLight({
                sourceType: hdsEffect.PointLightSourceType.SOFT,
                illuminatedType: hdsEffect.PointLightIlluminatedType.CONTENT
              })
              .shaderEffect({
                effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
                animation: {
                  duration: 5000,
                  iterations: -1
                },
                params: {
                  firstEdgeFlowLight: {
                    startPos: 0,
                    endPos: 1.0,
                    color: '#1AD0F1'
                  },
                  secondEdgeFlowLight: {
                    startPos: 0.5,
                    endPos: 1.5,
                    color: '#FFA4E5'
                  }
                }
              })
              .buildEffect())
            .onBlur(async () => {
              await this.dealWithAiContent()
            })
          TextInput({
            placeholder: '请输入内容',
            text: this.content!!
          })
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          Row() {
            Text('优先级')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Counter() {
              Text(String(this.priority))
            }
            .enableDec(this.priority > 0)
            .enableInc(this.priority < 9)
            .onInc(() => {
              this.priority++
            })
            .onDec(() => {
              this.priority--
            })
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Text('1最高，9最低，0、5中等。')
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          Row() {
            Text('开始时间')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              text: getDateTimeStringFromTimeStamp(this.startTime)
            })
              .enableAutoSpacing(true)
              .enabled(false)
              .layoutWeight(1)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .onClick(() => {
            this.UIContext.showDatePickerDialog({
              selected: new Date(this.startTime),
              showTime: true,
              useMilitaryTime: true,
              onDateAccept: async (value) => {
                if (value.getTime() > this.endTime && this.endTime !== -1) {
                  await promptAction.openToast({
                    message: '开始时间不能晚于结束时间'
                  })
                  return
                }
                this.startTime = value.getTime()
              }
            })
          })

          if (!this.teamId && !this.recurrence) {
            Row() {
              Text('提醒')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Toggle({
                type: ToggleType.Switch,
                isOn: this.remind!!
              })
                .enabled(this.remindEnabled)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            if (!this.remindEnabled) {
              Text('当前已存在的有效提醒数量已达到系统最大限制，不可开启提醒。可前往“我的”>“设置”>“通用”>“通用”>“功能”>“提醒管理”删除不必要的提醒后再开启提醒。')
                .fontColor($r('sys.color.warning'))
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
            }
          }
          Row() {
            Text('结束时间')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              text: this.endTime === -1 ? '无' : getDateTimeStringFromTimeStamp(this.endTime)
            })
              .enableAutoSpacing(true)
              .enabled(false)
              .layoutWeight(1)
            if (this.endTime !== -1) {
              Image($r('app.media.close'))
                .height(24)
                .margin({
                  left: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
                .onClick(() => {
                  this.endTime = -1
                })
            }
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })
          .onClick(() => {
            this.UIContext.showDatePickerDialog({
              selected: this.endTime !== -1 ? new Date(this.endTime) : new Date(),
              showTime: true,
              useMilitaryTime: true,
              onDateAccept: async (value) => {
                if (value.getTime() < this.startTime) {
                  await promptAction.openToast({
                    message: '结束时间不能早于开始时间'
                  })
                  return
                }
                this.endTime = value.getTime()
              }
            })
          })

          Row() {
            Text('预计耗时')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入预计耗时',
              text: this.duration!!
            })
              .enableAutoSpacing(true)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
              })
              .type(InputType.Number)
            Text('分钟')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('重复')
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            Toggle({
              type: ToggleType.Switch,
              isOn: this.recurrence!!
            })
              .enabled(this.teamId === '')
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          if (this.recurrence) {
            Row() {
              Text('周期')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Select(this.freq)
                .selected(this.recurrenceFreqIndex!!)
                .value(this.recurrenceFreqValue!!)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            if (this.recurrenceFreqIndex <= 3) {
              Row() {
                Text('步长')
                  .fontWeight(FontWeight.Medium)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                TextInput({
                  placeholder: '请输入步长，0无效',
                  text: this.recurrenceInterval!!
                })
                  .enableAutoSpacing(true)
                  .layoutWeight(1)
                  .type(InputType.Number)
              }
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
            }
            Row() {
              Text('截止时间')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                text: this.recurrenceUntil === -1 ? '无' : getDateTimeStringFromTimeStamp(this.recurrenceUntil)
              })
                .enableAutoSpacing(true)
                .enabled(false)
                .layoutWeight(1)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .onClick(() => {
              this.UIContext.showDatePickerDialog({
                selected: this.recurrenceUntil === -1 ? new Date() : new Date(this.recurrenceUntil),
                onDateAccept: async (value) => {
                  const time = value.getTime()
                  if (time < this.startTime) {
                    await promptAction.openToast({
                      message: '截止时间不能早于开始时间'
                    })
                    return
                  }
                  this.recurrenceUntil = time
                }
              })
            })

            Row() {
              Text('最大次数')
                .fontWeight(FontWeight.Medium)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              TextInput({
                placeholder: '请输入最大次数，0表示无限制',
                text: this.recurrenceCount!!
              })
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .type(InputType.Number)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Row() {
              Text('月')
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
                ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], (item: number) => {
                  Row() {
                    Toggle({
                      type: ToggleType.Checkbox,
                      isOn: this.recurrenceByMonth.includes(item)
                    })
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                      })
                      .onChange(isOn => {
                        if (!isOn) {
                          this.recurrenceByMonth.splice(this.recurrenceByMonth.indexOf(item), 1)
                        }
                        if (isOn && !this.recurrenceByMonth.includes(item)) {
                          this.recurrenceByMonth.push(item)
                        }
                      })
                    Text(item + '月')
                      .enableAutoSpacing(true)
                  }
                })
              }
              .layoutWeight(1)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Row() {
              Text('日')
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
                ForEach([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
                  27, 28, 29, 30, 31], (item: number) => {
                  Row() {
                    Toggle({
                      type: ToggleType.Checkbox,
                      isOn: this.recurrenceByMonthDay.includes(item)
                    })
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                      })
                      .onChange(isOn => {
                        if (!isOn) {
                          this.recurrenceByMonthDay.splice(this.recurrenceByMonthDay.indexOf(item), 1)
                        }
                        if (isOn && !this.recurrenceByMonthDay.includes(item)) {
                          this.recurrenceByMonthDay.push(item)
                        }
                      })
                    Text(item + '日')
                      .enableAutoSpacing(true)
                  }
                })
              }
              .layoutWeight(1)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })

            Row() {
              Text('星期')
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
                ForEach(['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'], (item: string) => {
                  Row() {
                    Toggle({
                      type: ToggleType.Checkbox,
                      isOn: this.recurrenceByDay.includes(item)
                    })
                      .margin({
                        right: $r('sys.float.ohos_id_elements_margin_horizontal_s')
                      })
                      .onChange(isOn => {
                        if (!isOn) {
                          this.recurrenceByDay.splice(this.recurrenceByDay.indexOf(item), 1)
                        }
                        if (isOn && !this.recurrenceByDay.includes(item)) {
                          this.recurrenceByDay.push(item)
                        }
                      })
                    Text(this.dayMap[item])
                  }
                })
              }
              .layoutWeight(1)
            }
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
          }
          Button('选择地点')
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
            .width('100%')
            .onClick(async () => {
              const res = await sceneMap.chooseLocation(this.context, {
                searchEnabled: true,
                showNearbyPoi: true
              })
              this.locationLatitude = res.location.latitude
              this.locationLongitude = res.location.longitude
              this.locationLocation = res.address
            })
          Row() {
            Text('纬度')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              text: String(this.locationLatitude)
            })
              .enableAutoSpacing(true)
              .enabled(false)
              .layoutWeight(1)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('经度')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              text: String(this.locationLongitude)
            })
              .enableAutoSpacing(true)
              .enabled(false)
              .layoutWeight(1)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          Row() {
            Text('地点')
              .fontWeight(FontWeight.Medium)
              .margin({
                right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
              })
            TextInput({
              placeholder: '请输入地点',
              text: this.locationLocation!!
            })
              .enableAutoSpacing(true)
              .layoutWeight(1)
          }
          .margin({
            top: $r('sys.float.ohos_id_elements_margin_vertical_m')
          })

          TextInput({
            placeholder: '请输入备注',
            text: this.bz!!
          })
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_m')
            })
        }
        .alignItems(HorizontalAlign.Start)
      }

      ListItem() {
        Column() {
          Text('标签')
            .fontWeight(FontWeight.Medium)
          TextInput({
            placeholder: '请输入内容',
            text: this.tag!!
          })
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .onBlur(() => {
              if (this.tag && !this.tagArray.includes(this.tag)) {
                this.tagArray.push(this.tag)
                this.tag = ''
              }
            })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.tagArray, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .enableAutoSpacing(true)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              if (index !== 0) {
                Image($r('app.media.up'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(() => {
                    const temp = this.tagArray[index]
                    this.tagArray[index] = this.tagArray[index - 1]
                    this.tagArray[index - 1] = temp
                  })
              }
              if (index !== this.tagArray.length - 1) {
                Image($r('app.media.down'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(() => {
                    const temp = this.tagArray[index]
                    this.tagArray[index] = this.tagArray[index + 1]
                    this.tagArray[index + 1] = temp
                  })
              }
              Image($r('app.media.delete'))
                .height(24)
                .onClick(() => {
                  this.tagArray.splice(index, 1)
                })
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
      })
      ListItem() {
        Column() {
          Text('依赖待办')
            .fontWeight(FontWeight.Medium)
          TextInput({
            placeholder: '请输入依赖待办ID',
            text: this.dependency!!
          })
            .enableAutoSpacing(true)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .onBlur(() => {
              if (this.dependency && !this.dependencyArray.includes(this.dependency)) {
                this.dependencyArray.push(this.dependency)
                this.dependency = ''
              }
            })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ForEach(this.dependencyArray, (item: string, index) => {
        ListItem() {
          Column() {
            Row() {
              Text(item)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Image($r('app.media.delete'))
                .height(24)
                .onClick(() => {
                  this.dependencyArray.splice(index, 1)
                })
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
      })
      ListItem() {
        Column() {
          Text('动作')
            .fontWeight(FontWeight.Medium)
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
          Select([
            { value: '打开应用' },
            { value: '打开指定类型应用' },
            { value: '打开链接' },
            { value: '打开文件' },
            { value: '拨号' }
          ])
            .margin({
              top: $r('sys.float.ohos_id_elements_margin_vertical_l')
            })
            .selected(this.actionTypeIndex!!)
            .value(this.actionTypeValue!!)
            .onSelect(() => {
              this.actionValue = ''
            })
          if (this.actionTypeValue === '打开应用') {
            TextInput({
              placeholder: '请输入Want对象序列化字符串',
              text: this.actionValue!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onBlur(() => {
                if (this.actionValue) {
                  try {
                    JSON.parse(this.actionValue)
                    this.actionArray.push({
                      type: 'openApp',
                      value: this.actionValue
                    })
                    this.actionTypeIndex = 0
                    this.actionTypeValue = '打开应用'
                    this.actionValue = ''
                  } catch {
                  }
                }
              })
            Text('Want介绍')
              .enableAutoSpacing(true)
              .fontColor($r('sys.color.font_emphasize'))
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onClick(async () => {
                await openLink(this.context,
                  'https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-ability-want')
              })
            Text('示例：{"bundleName":"com.huawei.hmos.settings","abilityName":"com.huawei.hmos.settings.MainAbility","uri":"application_info_entry","parameters":{"pushParams":"com.zhangxm.aitodo"}}（打开系统“设置”应用的“轩铭智能待办”应用权限管理页面）')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.actionTypeValue === '打开指定类型应用') {
            TextInput({
              placeholder: '请输入入参JSON对象序列化字符串',
              text: this.actionValue!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onBlur(() => {
                if (this.actionValue) {
                  try {
                    JSON.parse(this.actionValue)
                    this.actionArray.push({
                      type: 'openAppByType',
                      value: this.actionValue
                    })
                    this.actionTypeIndex = 0
                    this.actionTypeValue = '打开应用'
                    this.actionValue = ''
                  } catch {
                  }
                }
              })
            Text('入参对象介绍')
              .fontColor($r('sys.color.font_emphasize'))
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .onClick(async () => {
                await openLink(this.context,
                  'https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-inner-application-uiabilitycontext#startabilitybytype11-1')
              })
            Text('示例：{"type":"mail","wantParam":{"sceneType":1,"email":["2300990296@qq.com"],"subject":"主题","body":"正文"}}')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
          }
          if (this.actionTypeValue === '打开链接') {
            TextInput({
              placeholder: '请输入链接',
              text: this.actionValue!!
            })
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.URL)
              .onBlur(() => {
                if (this.actionValue) {
                  this.actionArray.push({
                    type: 'openUrl',
                    value: this.actionValue
                  })
                  this.actionTypeIndex = 0
                  this.actionTypeValue = '打开应用'
                  this.actionValue = ''
                }
              })
          }
          if (this.actionTypeValue === '打开文件') {
            Button('选择文件')
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .width('100%')
              .onClick(async () => {
                const documentSelectOptions = new picker.DocumentSelectOptions()
                documentSelectOptions.maxSelectNumber = 1
                const documentViewPicker = new picker.DocumentViewPicker(this.context)
                const uris = await documentViewPicker.select(documentSelectOptions)
                if (uris.length === 1) {
                  const uri = uris[0]
                  await fileShare.persistPermission([{
                    uri: uri,
                    operationMode: fileShare.OperationMode.READ_MODE
                  }])
                  this.actionArray.push({
                    type: 'openFile',
                    value: uri
                  })
                  this.actionTypeIndex = 0
                  this.actionTypeValue = '打开应用'
                  this.actionValue = ''
                }
              })
          }
          if (this.actionTypeValue === '拨号') {
            TextInput({
              placeholder: '请输入手机号',
              text: this.actionValue!!
            })
              .contentType(ContentType.PHONE_NUMBER)
              .enableAutoSpacing(true)
              .margin({
                top: $r('sys.float.ohos_id_elements_margin_vertical_m')
              })
              .type(InputType.PhoneNumber)
              .onBlur(() => {
                if (this.actionValue) {
                  this.actionArray.push({
                    type: 'callTelephone',
                    value: this.actionValue
                  })
                  this.actionTypeIndex = 0
                  this.actionTypeValue = '打开应用'
                  this.actionValue = ''
                }
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }

      ForEach(this.actionArray, (item: Action, index) => {
        ListItem() {
          Column() {
            Row() {
              Column() {
                Text(item.value)
                  .enableAutoSpacing(true)
                  .fontWeight(FontWeight.Medium)
                Text(this.actionTypeMap[item.type])
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

              if (index !== 0) {
                Image($r('app.media.up'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(() => {
                    const temp = this.actionArray[index]
                    this.actionArray[index] = this.actionArray[index - 1]
                    this.actionArray[index - 1] = temp
                  })
              }
              if (index !== this.actionArray.length - 1) {
                Image($r('app.media.down'))
                  .height(24)
                  .margin({
                    right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                  })
                  .onClick(() => {
                    const temp = this.actionArray[index]
                    this.actionArray[index] = this.actionArray[index + 1]
                    this.actionArray[index + 1] = temp
                  })
              }
              Image($r('app.media.delete'))
                .height(24)
                .onClick(async () => {
                  if (item.type === 'openFile') {
                    await fileShare.revokePermission([{
                      uri: item.value,
                      operationMode: fileShare.OperationMode.READ_MODE
                    }])
                  }
                  this.actionArray.splice(index, 1)
                })
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
      })
      ListItem() {
        Column() {
          Column() {
            Row() {
              Text('云备份')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
                .margin({
                  right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                })
              Toggle({
                type: ToggleType.Switch,
                isOn: this.cloudBackup!!
              })
                .enabled(this.allowCloudBackup)
            }
            .borderRadius(12)
            .padding(12)
          }
          .backgroundColor($r('sys.color.ohos_id_color_card_bg'))
          .borderRadius($r('sys.float.ohos_id_corner_radius_default_l'))
          .padding($r('sys.float.ohos_id_corner_radius_mark'))

          if (!this.allowCloudBackup) {
            Text(this.alertText)
              .fontColor($r('sys.color.warning'))
              .fontSize($r('sys.float.ohos_id_text_size_body3'))
              .margin({
                top: 6,
                left: 12,
                right: 12
              })
          }
        }
        .alignItems(HorizontalAlign.Start)
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })

      ListItem() {
        Button('新增')
          .width('100%')
          .onClick(async () => {
            if (!this.content) {
              await promptAction.openToast({
                message: '请输入内容'
              })
              return
            }
            if (!this.duration) {
              await promptAction.openToast({
                message: '请输入预计耗时'
              })
              return
            }
            let recurrenceRule = ''
            if (this.recurrence) {
              recurrenceRule = 'FREQ='
              const rfcFreqMap: Record<number, string> = {
                0: 'YEARLY',
                1: 'MONTHLY',
                2: 'WEEKLY',
                3: 'DAILY'
              }
              if (this.recurrenceFreqIndex <= 3) {
                recurrenceRule += rfcFreqMap[this.recurrenceFreqIndex]
                if (Number(this.recurrenceInterval) > 0) {
                  recurrenceRule += ';INTERVAL='
                  recurrenceRule += this.recurrenceInterval
                }
              }
              if (this.recurrenceFreqIndex > 3) {
                recurrenceRule += this.recurrenceFreqValue
              }
              if (this.recurrenceUntil !== -1) {
                recurrenceRule += ';UNTIL='
                recurrenceRule += timeStampToIcsTimeString(this.recurrenceUntil)
              }
              if (Number(this.recurrenceCount) > 0) {
                recurrenceRule += ';COUNT='
                recurrenceRule += this.recurrenceCount
              }
              if (this.recurrenceByMonth.length > 0) {
                recurrenceRule += ';BYMONTH='
                recurrenceRule += this.recurrenceByMonth.join(',')
              }
              if (this.recurrenceByMonthDay.length > 0) {
                recurrenceRule += ';BYMONTHDAY='
                recurrenceRule += this.recurrenceByMonthDay.join(',')
              }
              if (this.recurrenceByDay.length > 0) {
                recurrenceRule += ';BYDAY='
                recurrenceRule += this.recurrenceByDay.join(',')
              }
            }
            if (!this.teamId) {
              await newTodo(this.context, {
                content: this.content,
                priority: this.priority,
                startTime: this.startTime,
                endTime: this.endTime,
                duration: Number(this.duration) * 60000,
                recurrenceRule: recurrenceRule,
                excludeTime: [],
                tag: this.tagArray,
                dependency: this.dependencyArray,
                location: {
                  latitude: this.locationLatitude,
                  longitude: this.locationLongitude,
                  location: this.locationLocation
                },
                action: this.actionArray,
                bz: this.bz,
                cloudBackup: this.cloudBackup,
                remind: this.remind
              })
            }
            if (this.teamId) {
              //请求团队新增待办API
            }
            this.isShowNewSheet = false
          })
      }
      .margin({
        top: $r('sys.float.ohos_id_elements_margin_vertical_l')
      })
    }
    .padding({
      bottom: $r('sys.float.ohos_id_default_padding_bottom_fixed'),
      left: $r('sys.float.ohos_id_elements_margin_horizontal_l'),
      right: $r('sys.float.ohos_id_elements_margin_horizontal_l')
    })
    .onAppear(async () => {
      await textProcessing.init()
      this.freq = ['年', '月', '周', '日'].concat(getCustomFreqList(this.context).map(item => item.name))
        .map((item): SelectOption => {
          return {
            value: item
          }
        })
      this.remindEnabled = await isProxyReminderEnabled()
      const res = await getCloudServiceStatus(this.context)
      const key = getKeyAlg()
      if (!res) {
        this.alertText = '未登录账号或账号未开通云服务，云备份不可用'
      }
      if (res) {
        if (!key) {
          this.alertText = '未导入密钥，云备份不可用。请前往“我的”>“设置”>“密钥”导入密钥'
        }
        if (key) {
          this.allowCloudBackup = true
          this.cloudBackup = getFlushPreference(this.context, 'cloudbackupSetting', 'autoOn', false) as boolean
        }
      }
    })
    .onDisAppear(async () => {
      await textProcessing.release()
    })
  }
}