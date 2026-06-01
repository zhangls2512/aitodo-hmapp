import { util } from '@kit.ArkTS'
import { promptAction } from '@kit.ArkUI'
import { asset } from '@kit.AssetStoreKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { huks } from '@kit.UniversalKeystoreKit'

export interface EncryptData {
  content: string,
  iv: string
}

interface CustomKey {
  wrappedKey: string,
  alg: string
}

function stringToArray(str: string) {
  return new util.TextEncoder().encodeInto(str)
}

function arrayToString(arr: Uint8Array) {
  return util.TextDecoder.create().decodeToString(arr)
}

function encodeBase64(arr: Uint8Array) {
  return new util.Base64Helper().encodeToStringSync(arr)
}

function decodeBase64(arr: string) {
  return new util.Base64Helper().decodeSync(arr)
}

export function getKeyAlg(): string {
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray('key'))
  query.set(asset.Tag.RETURN_TYPE, asset.ReturnType.ALL)
  try {
    const keyres = asset.querySync(query)
    const keyAlg = keyres[0].get(asset.Tag.SECRET) as Uint8Array
    return arrayToString(keyAlg)
  } catch {
    return ''
  }
}

export async function importRandomKey(alg: string) {
  if (alg === 'AES256') {
    await huks.generateKeyItem('key', {
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        },
        {
          tag: huks.HuksTag.HUKS_TAG_IS_ALLOWED_WRAP,
          value: true
        }
      ]
    })
  }
  if (alg === 'SM4') {
    await huks.generateKeyItem('key', {
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_SM4
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_SM4_KEY_SIZE_128
        },
        {
          tag: huks.HuksTag.HUKS_TAG_IS_ALLOWED_WRAP,
          value: true
        }
      ]
    })
  }
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.SECRET, stringToArray(alg))
  query.set(asset.Tag.ALIAS, stringToArray('key'))
  query.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE)
  asset.addSync(query)
  await promptAction.openToast({
    message: '导入成功'
  })
}

export async function importCustomKey(key: string) {
  try {
    const customKey = JSON.parse(key) as CustomKey
    if (customKey.alg === 'AES256') {
      await huks.unwrapKeyItem('key', {
        properties: [
          {
            tag: huks.HuksTag.HUKS_TAG_KEY_WRAP_TYPE,
            value: huks.HuksKeyWrapType.HUKS_KEY_WRAP_TYPE_HUK_BASED
          }
        ]
      }, decodeBase64(customKey.wrappedKey))
    }
    if (customKey.alg === 'SM4') {
      await huks.unwrapKeyItem('key', {
        properties: [
          {
            tag: huks.HuksTag.HUKS_TAG_KEY_WRAP_TYPE,
            value: huks.HuksKeyWrapType.HUKS_KEY_WRAP_TYPE_HUK_BASED
          }
        ]
      }, decodeBase64(customKey.wrappedKey))
    }
    const query: asset.AssetMap = new Map()
    query.set(asset.Tag.SECRET, stringToArray(customKey.alg))
    query.set(asset.Tag.ALIAS, stringToArray('key'))
    query.set(asset.Tag.CONFLICT_RESOLUTION, asset.ConflictResolution.OVERWRITE)
    asset.addSync(query)
    await promptAction.openToast({
      message: '导入成功'
    })
  } catch (err) {
    if (!err.code) {
      await promptAction.openToast({
        message: '导入失败'
      })
    }
    if (err.code) {
      await promptAction.openToast({
        message: '导入失败，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
      })
    }
  }
}

export async function exportKey(): Promise<CustomKey | 'fail'> {
  try {
    const res = await huks.wrapKeyItem('key', {
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_WRAP_TYPE,
          value: huks.HuksKeyWrapType.HUKS_KEY_WRAP_TYPE_HUK_BASED
        }
      ]
    })
    return {
      wrappedKey: encodeBase64(res.outData as Uint8Array),
      alg: getKeyAlg()
    }
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
    })
    return 'fail'
  }
}

export async function removeKey() {
  await huks.deleteKeyItem('key', {})
  const query: asset.AssetMap = new Map()
  query.set(asset.Tag.ALIAS, stringToArray('key'))
  asset.removeSync(query)
  await promptAction.openToast({
    message: '删除成功'
  })
}

export async function encrypt(content: string): Promise<EncryptData> {
  const random = cryptoFramework.createRandom()
  random.enableHardwareEntropy()
  const iv = random.generateRandomSync(16).data
  const keyAlg = getKeyAlg()
  if (keyAlg === 'AES256') {
    const options: huks.HuksOptions = {
      inData: stringToArray(content),
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        },
        {
          tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
          value: huks.HuksCipherMode.HUKS_MODE_CBC
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PADDING,
          value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
        },
        {
          tag: huks.HuksTag.HUKS_TAG_IV,
          value: iv
        }
      ]
    }
    const session = await huks.initSession('key', options)
    const res = await huks.finishSession(session.handle, options)
    return {
      content: encodeBase64(res.outData as Uint8Array),
      iv: encodeBase64(iv)
    }
  }
  if (keyAlg === 'SM4') {
    const options: huks.HuksOptions = {
      inData: stringToArray(content),
      properties: [
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_SM4
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_SM4_KEY_SIZE_128
        },
        {
          tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
          value: huks.HuksCipherMode.HUKS_MODE_CBC
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PADDING,
          value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
        },
        {
          tag: huks.HuksTag.HUKS_TAG_IV,
          value: iv
        }
      ]
    }
    const session = await huks.initSession('key', options)
    const res = await huks.finishSession(session.handle, options)
    return {
      content: encodeBase64(res.outData as Uint8Array),
      iv: encodeBase64(iv)
    }
  }
  return {
    content: '',
    iv: ''
  }
}

export async function decrypt(encryptData: EncryptData): Promise<string> {
  try {
    const keyAlg = getKeyAlg()
    if (keyAlg === 'AES256') {
      const options: huks.HuksOptions = {
        inData: decodeBase64(encryptData.content),
        properties: [
          {
            tag: huks.HuksTag.HUKS_TAG_PURPOSE,
            value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
          },
          {
            tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
            value: huks.HuksKeyAlg.HUKS_ALG_AES
          },
          {
            tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
            value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
          },
          {
            tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
            value: huks.HuksCipherMode.HUKS_MODE_CBC
          },
          {
            tag: huks.HuksTag.HUKS_TAG_PADDING,
            value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
          },
          {
            tag: huks.HuksTag.HUKS_TAG_IV,
            value: decodeBase64(encryptData.iv)
          }
        ]
      }
      const session = await huks.initSession('key', options)
      const res = await huks.finishSession(session.handle, options)
      return arrayToString(res.outData as Uint8Array)
    }
    if (keyAlg === 'SM4') {
      const options: huks.HuksOptions = {
        inData: decodeBase64(encryptData.content),
        properties: [
          {
            tag: huks.HuksTag.HUKS_TAG_PURPOSE,
            value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
          },
          {
            tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
            value: huks.HuksKeyAlg.HUKS_ALG_SM4
          },
          {
            tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
            value: huks.HuksKeySize.HUKS_SM4_KEY_SIZE_128
          },
          {
            tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
            value: huks.HuksCipherMode.HUKS_MODE_CBC
          },
          {
            tag: huks.HuksTag.HUKS_TAG_PADDING,
            value: huks.HuksKeyPadding.HUKS_PADDING_PKCS7
          },
          {
            tag: huks.HuksTag.HUKS_TAG_IV,
            value: decodeBase64(encryptData.iv)
          }
        ]
      }
      const session = await huks.initSession('key', options)
      const res = await huks.finishSession(session.handle, options)
      return arrayToString(res.outData as Uint8Array)
    }
    return 'fail'
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
    })
    return 'fail'
  }
}