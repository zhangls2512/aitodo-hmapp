import { preferences } from '@kit.ArkData'
import { deleteFlushPreferenceKey, setFlushPreference } from './Preference'

interface CustomFreq {
  name: string,
  list: YMD[]
}

interface YMD {
  year: number,
  month: number,
  day: number
}

export function getCustomFreqList(context: Context) {
  const dataPreferences = preferences.getPreferencesSync(context, {
    name: 'customFreq',
    storageType: preferences.StorageType.GSKV
  })
  const kvsobject = dataPreferences.getAllSync() as object
  return Object.keys(kvsobject).map(key => {
    return {
      name: key,
      list: kvsobject[key].split(',').sort((a: string, b: string) => Number(a) - Number(b)).map((item: string) => {
        return {
          year: Number(item.substring(0, 4)),
          month: Number(item.substring(4, 6)) - 1,
          day: Number(item.substring(6, 8))
        } as YMD
      })
    } as CustomFreq
  })
}

export function setCustomFreq(context: Context, name: string, value: string) {
  setFlushPreference(context, 'customFreq', name, value)
}

export function removeCustomFreq(context: Context, name: string) {
  deleteFlushPreferenceKey(context, 'customFreq', name)
}