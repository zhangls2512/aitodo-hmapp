import { common } from '@kit.AbilityKit'
import { util } from '@kit.ArkTS'
import { LengthMetrics, LoadingDialog, promptAction } from '@kit.ArkUI'
import { fido2 } from '@kit.OnlineAuthenticationKit'
import { hdsMaterial, HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType } from '@kit.UIDesignKit'
import { getPersonalAccountInfo } from '../common/Account'
import { developerRequest } from '../common/Request'

@Builder
export function NewpasskeyBuilder() {
  Newpasskey()
}

@ComponentV2
struct Newpasskey {
  @Local email: string = ''
  @Local credentialId: string = ''
  @Local publicKey: string = ''
  @Local type: string = 'mfa'
  @Local buttonText: string = '获取验证码'
  @Local buttonEnabled: boolean = true
  context = this.getUIContext().getHostContext() as common.UIAbilityContext
  pageInfos = new NavPathStack()
  mfa = ''
  emailcode = ''
  dialogControllerProgress = new CustomDialogController({
    builder: LoadingDialog({
      content: '请求中...'
    })
  })

  getNumber(data: number, start: number, end: number) {
    const binarystring = data.toString(2).padStart(8, '0')
    const resultstring = binarystring.substring(start, end + 1)
    return parseInt(resultstring, 2)
  }

  getPublicKey(attestationObject: Uint8Array) {
    let publicKey = ''
    const data = Array.from(attestationObject)
    let offset = 0
    let pendingParseKeyCount = this.getNumber(data[offset], 3, 7)
    while (pendingParseKeyCount > 0) {
      offset++
      offset += this.getNumber(data[offset], 3, 7)
      offset++
      const valueType = this.getNumber(data[offset], 0, 2)
      if (valueType === 2) {
        let valueValueLength = this.getNumber(data[offset], 3, 7)
        if (valueValueLength === 24) {
          offset++
          valueValueLength = data[offset]
        }
        if (valueValueLength === 25) {
          offset++
          let lengthstring = data[offset].toString(2).padStart(8, '0')
          offset++
          lengthstring += data[offset].toString(2).padStart(8, '0')
          valueValueLength = parseInt(lengthstring, 2)
        }
        if (valueValueLength === 26) {
          let lengthstring = ''
          for (let i = 0; i < 4; i++) {
            offset++
            lengthstring += data[offset].toString(2).padStart(8, '0')
          }
          valueValueLength = parseInt(lengthstring, 2)
        }
        if (valueValueLength === 27) {
          let lengthstring = ''
          for (let i = 0; i < 8; i++) {
            offset++
            lengthstring += data[offset].toString(2).padStart(8, '0')
          }
          valueValueLength = parseInt(lengthstring, 2)
        }
        const authData: number[] = []
        for (let i = 1; i <= valueValueLength; i++) {
          offset++
          authData.push(data[offset])
        }
        const credentialIdLength =
          parseInt(authData[53].toString(2).padStart(8, '0') + authData[54].toString(2).padStart(8, '0'), 2)
        const cosePublicKey: number[] = []
        for (let i = 55 + credentialIdLength; i < authData.length; i++) {
          cosePublicKey.push(authData[i])
        }
        const publickeyx: number[] = []
        for (let i = 10; i < 42; i++) {
          publickeyx.push(cosePublicKey[i])
        }
        const publickeyy: number[] = []
        for (let i = 45; i < 77; i++) {
          publickeyy.push(cosePublicKey[i])
        }
        const derPublicKeyHeader =
          [48, 89, 48, 19, 6, 7, 42, 134, 72, 206, 61, 2, 1, 6, 8, 42, 134, 72, 206, 61, 3, 1, 7, 3, 66, 0, 4]
        publicKey = new util.Base64Helper().encodeToStringSync(new Uint8Array(derPublicKeyHeader.concat(publickeyx)
          .concat(publickeyy)), util.Type.BASIC_URL_SAFE)
      }
      if (valueType === 3) {
        offset += this.getNumber(data[offset], 3, 7)
      }
      if (valueType === 5) {
        let pendingParseKeyCounta = this.getNumber(data[offset], 3, 7)
        while (pendingParseKeyCounta > 0) {
          offset++
          offset += this.getNumber(data[offset], 3, 7)
          offset++
          const valueTypea = this.getNumber(data[offset], 0, 2)
          if (valueTypea === 2) {
            let valueValueLength = this.getNumber(data[offset], 3, 7)
            if (valueValueLength === 24) {
              offset++
              valueValueLength = data[offset]
            }
            if (valueValueLength === 25) {
              offset++
              let lengthstring = data[offset].toString(2).padStart(8, '0')
              offset++
              lengthstring += data[offset].toString(2).padStart(8, '0')
              valueValueLength = parseInt(lengthstring, 2)
            }
            if (valueValueLength === 26) {
              let lengthstring = ''
              for (let i = 0; i < 4; i++) {
                offset++
                lengthstring += data[offset].toString(2).padStart(8, '0')
              }
              valueValueLength = parseInt(lengthstring, 2)
            }
            if (valueValueLength === 27) {
              let lengthstring = ''
              for (let i = 0; i < 8; i++) {
                offset++
                lengthstring += data[offset].toString(2).padStart(8, '0')
              }
              valueValueLength = parseInt(lengthstring, 2)
            }
            offset += valueValueLength
          }
          if (valueTypea === 3) {
            offset += this.getNumber(data[offset], 3, 7)
          }
          if (valueTypea === 4) {
            let pendingParseItemCount = this.getNumber(data[offset], 3, 7)
            while (pendingParseItemCount > 0) {
              offset++
              let itemLength = this.getNumber(data[offset], 3, 7)
              if (itemLength === 24) {
                offset++
                itemLength = data[offset]
              }
              if (itemLength === 25) {
                offset++
                let lengthstring = data[offset].toString(2).padStart(8, '0')
                offset++
                lengthstring += data[offset].toString(2).padStart(8, '0')
                itemLength = parseInt(lengthstring, 2)
              }
              if (itemLength === 26) {
                let lengthstring = ''
                for (let i = 0; i < 4; i++) {
                  offset++
                  lengthstring += data[offset].toString(2).padStart(8, '0')
                }
                itemLength = parseInt(lengthstring, 2)
              }
              if (itemLength === 27) {
                let lengthstring = ''
                for (let i = 0; i < 8; i++) {
                  offset++
                  lengthstring += data[offset].toString(2).padStart(8, '0')
                }
                itemLength = parseInt(lengthstring, 2)
              }
              offset += itemLength
              pendingParseItemCount--
            }
          }
          pendingParseKeyCounta--
        }
      }
      pendingParseKeyCount--
    }
    return publicKey
  }

  build() {
    HdsNavDestination() {
      List() {
        ListItem()
          .margin({
            top: 64
          })
        if (this.email && this.credentialId && this.publicKey) {
          ListItem() {
            Column() {
              Row() {
                Text('方式')
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
                      value: 'mfa',
                      group: 'type'
                    })
                      .checked(this.type === 'mfa' ? true : false)
                      .onChange(isChecked => {
                        if (isChecked) {
                          this.type = 'mfa'
                        }
                      })
                    Text('MFA')
                  }

                  Row() {
                    Radio({
                      value: 'emailcode',
                      group: 'type'
                    })
                      .checked(this.type === 'emailcode' ? true : false)
                      .onChange(isChecked => {
                        if (isChecked) {
                          this.type = 'emailcode'
                        }
                      })
                    Text('邮箱验证码')
                  }
                }
                .layoutWeight(1)
              }

              if (this.type === 'mfa') {
                Row() {
                  Text('MFA')
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  TextInput({
                    placeholder: '请输入MFA',
                    text: this.mfa!!
                  })
                    .enableAutoSpacing(true)
                    .layoutWeight(1)
                    .maxLength(6)
                    .type(InputType.ONE_TIME_CODE)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })
              }
              if (this.type === 'emailcode') {
                Row() {
                  Text('验证码')
                    .fontWeight(FontWeight.Medium)
                    .margin({
                      right: $r('sys.float.ohos_id_elements_margin_horizontal_m')
                    })
                  TextInput({
                    placeholder: '请输入邮箱验证码',
                    text: this.emailcode!!
                  })
                    .enableAutoSpacing(true)
                    .layoutWeight(1)
                    .maxLength(8)
                    .type(InputType.ONE_TIME_CODE)
                }
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                })

                Button(this.buttonText)
                  .buttonStyle(ButtonStyleMode.NORMAL)
                  .enabled(this.buttonEnabled)
                  .margin({
                    top: $r('sys.float.ohos_id_elements_margin_vertical_m')
                  })
                  .width('100%')
                  .onClick(async () => {
                    this.dialogControllerProgress.open()
                    const res = await developerRequest(this.context, '/account/sendEmailCode', {
                      email: this.email
                    })
                    this.dialogControllerProgress.close()
                    if (res !== 'fail') {
                      await promptAction.openToast({
                        message: '验证码已成功发送到邮箱：' + this.email
                      })
                      this.buttonEnabled = false
                      let countdown = 60
                      const interval = setInterval(() => {
                        countdown--
                        if (countdown > 0) {
                          this.buttonText = '重新发送 (' + countdown + ')'
                        } else {
                          clearInterval(interval)
                          this.buttonEnabled = true
                          this.buttonText = '获取验证码'
                        }
                      }, 1000)
                    }
                  })
              }
              Button('新增')
                .margin({
                  top: $r('sys.float.ohos_id_elements_margin_vertical_l')
                })
                .width('100%')
                .onClick(async () => {
                  if (this.type === 'mfa' && this.mfa.length !== 6) {
                    await promptAction.openToast({
                      message: '请输入正确的 MFA'
                    })
                    return
                  }
                  if (this.type === 'emailcode' && this.emailcode.length !== 8) {
                    await promptAction.openToast({
                      message: '请输入正确的邮箱验证码'
                    })
                    return
                  }
                  let code = ''
                  if (this.type === 'mfa') {
                    code = this.mfa
                  }
                  if (this.type === 'emailcode') {
                    code = this.emailcode
                  }
                  this.dialogControllerProgress.open()
                  const res = await developerRequest(this.context, '/account/bindExternalAccount', {
                    email: this.email,
                    verifyType: this.type,
                    verifyCode: code,
                    platform: 'passkey',
                    credentialId: this.credentialId,
                    publicKey: this.publicKey
                  })
                  this.dialogControllerProgress.close()
                  if (res !== 'fail') {
                    await promptAction.openToast({
                      message: '新增成功'
                    })
                    this.pageInfos.pop()
                  }
                })
            }
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
          mainTitle: '新增通行密钥'
        }
      }
    })
    .titleMode(HdsNavDestinationTitleMode.MODAL)
    .onReady(async (context) => {
      this.pageInfos = context.pathStack
      const accountInfo = await getPersonalAccountInfo()
      this.email = accountInfo.email
      if (this.email) {
        try {
          const res = await fido2.register(this.context, {
            publicKey: {
              rp: {
                id: 'www.zhangls2512.cn',
                name: 'www.zhangls2512.cn'
              },
              user: {
                id: new util.TextEncoder().encodeInto(accountInfo.uid),
                name: accountInfo.email,
                displayName: accountInfo.email
              },
              challenge: new util.TextEncoder().encodeInto(String(Date.now()).slice(0, -5) + '00000'),
              pubKeyCredParams: [
                {
                  type: fido2.PublicKeyCredentialType.PUBLIC_KEY,
                  alg: fido2.Algorithm.ES256
                }
              ],
              authenticatorSelection: {
                residentKey: fido2.UserVerificationRequirement.PREFERRED
              }
            }
          })
          this.credentialId = new util.Base64Helper().encodeToStringSync(res.rawId, util.Type.BASIC_URL_SAFE)
          this.publicKey = this.getPublicKey(res.response.attestationObject)
        } catch (err) {
          if (err.code !== 1021300004) {
            await promptAction.openToast({
              message: '发生错误，错误码：' + err.code + '，错误信息：' + err.message
            })
          }
          if (err.code === 1021300004) {
            this.pageInfos.pop()
          }
        }
      }
    })
  }
}