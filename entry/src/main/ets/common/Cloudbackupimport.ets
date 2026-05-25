import { relationalStore } from '@kit.ArkData'
import { getPersonalAccountAccessToken } from './Account'
import { decrypt, getKeyAlg } from './Crypto'
import { Action, Location } from './Datachange'
import { CloudBackupTimeItem } from './Dataget'
import { importTodo, TodoItem } from './Dataimport'
import { developerRequest } from './Request'

interface Item {
  id: string,
  content: string,
  iv: string
}

interface TodoCloudBackup {
  content: string,
  priority: number,
  startTime: number,
  endTime: number,
  duration: number,
  recurrenceRule: string,
  excludeTime: number[],
  tag: string[],
  dependency: string[],
  location: Location,
  action: Action[],
  bz: string,
  recentCompletedTime: number,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[]
}

export async function importCloudBackupTodo(context: Context, conflict: relationalStore.ConflictResolution) {
  const accessToken = await getPersonalAccountAccessToken()
  if (accessToken && getKeyAlg()) {
    const countResponse = await developerRequest(context, '/todo/getBackupCount', {
      accessToken: accessToken
    })
    if (countResponse !== 'fail') {
      const total = JSON.parse(countResponse).count as number
      for (let i = 0; i < total; i += 50) {
        const listResponse = await developerRequest(context, '/todo/getBackupList', {
          accessToken: accessToken,
          skip: i,
          limit: 50
        })
        if (listResponse !== 'fail') {
          const array = JSON.parse(listResponse).data as Item[]
          const todoArray: TodoItem[] = []
          const promises = array.map(async (item) => {
            const itemstring = await decrypt({
              content: item.content,
              iv: item.iv
            })
            if (itemstring !== 'fail') {
              const itemobject = JSON.parse(itemstring) as TodoCloudBackup
              todoArray.push({
                id: item.id,
                content: itemobject.content,
                priority: itemobject.priority,
                startTime: itemobject.startTime,
                endTime: itemobject.endTime,
                duration: itemobject.duration,
                recurrenceRule: itemobject.recurrenceRule,
                excludeTime: itemobject.excludeTime,
                tag: itemobject.tag,
                dependency: itemobject.dependency,
                location: itemobject.location,
                action: itemobject.action,
                bz: itemobject.bz,
                recentCompletedTime: itemobject.recentCompletedTime,
                updateTime: itemobject.updateTime,
                cloudBackupTime: itemobject.cloudBackupTime
              })
            }
          })
          await Promise.all(promises)
          await importTodo(context, JSON.stringify(todoArray), conflict)
        }
      }
      return 'success'
    }
  }
  return 'fail'
}