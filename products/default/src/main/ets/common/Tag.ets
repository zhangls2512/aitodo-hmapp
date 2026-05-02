import { read } from './File'

export interface Tag {
  value: string,
  priority: number
}

export async function getTagList(context: Context) {
  const res = await read(context.filesDir + '/tag.txt', true)
  if (res !== 'fail') {
    return JSON.parse(res) as Tag[]
  }
  return []
}

export async function getTagMap(context: Context) {
  const map = new Map<string, number>()
  const res = await read(context.filesDir + '/tag.txt', true)
  if (res !== 'fail') {
    const tagArray = JSON.parse(res) as Tag[]
    tagArray.forEach(item => {
      map.set(item.value, item.priority)
    })
    return map
  }
  return map
}