import { relationalStore } from '@kit.ArkData'
import { getTeamAccountList } from './Account'
import { Todo } from './Dataget'
import { teamRequest } from './Request'
import { autoSyncTable } from './Table'
import { UserItem } from '../pages/Newtodo'

export async function getTeamUserList(context: Context, teamId: string) {
  let result: UserItem[] = []
  while (true) {
    const res = await teamRequest(context, teamId, '/getUserList', {
      skip: result.length
    })
    if (res !== 'fail') {
      const userArray = JSON.parse(res).data as UserItem[]
      result = result.concat(userArray)
      if (userArray.length < 10) {
        break
      }
    }
    if (res === 'fail') {
      break
    }
  }
  return result
}

export async function deleteCompleteTeamTodo(context: Context, teamId: string) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'todo',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('todo')
  predicates.equalTo('teamId', teamId)
  rdbStore.deleteSync(predicates)
  await rdbStore.close()
}

export async function syncCompleteTeamTodo(context: Context, teamId: string, autoSync = true) {
  let result: Todo[] = []
  let after = true
  while (true) {
    const res = await teamRequest(context, teamId, '/getTodoList', {
      type: 'complete',
      time: -1,
      skip: result.length
    })
    if (res !== 'fail') {
      const todoArray = JSON.parse(res).data as Todo[]
      result = result.concat(todoArray)
      if (todoArray.length < 10) {
        break
      }
    }
    if (res === 'fail') {
      after = false
      break
    }
  }
  if (after) {
    await deleteCompleteTeamTodo(context, teamId)
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    result.forEach(item => {
      rdbStore.insertSync('todo', {
        id: item.id,
        teamId: teamId,
        content: item.content,
        priority: item.priority,
        startTime: item.startTime,
        endTime: item.endTime,
        duration: item.duration,
        recurrenceRule: item.recurrenceRule,
        excludeTime: JSON.stringify(item.excludeTime),
        tag: JSON.stringify(item.tag),
        dependency: JSON.stringify(item.dependency),
        location: JSON.stringify(item.location),
        action: JSON.stringify(item.action),
        bz: item.bz,
        recentCompletedTime: item.recentCompletedTime,
        updateTime: item.updateTime,
        cloudBackupTime: JSON.stringify([])
      })
    })
    await rdbStore.close()
    if (autoSync) {
      await autoSyncTable(context)
    }
  }
}

export async function syncAllTeamCompleteTodo(context: Context) {
  const teamAccounts = await getTeamAccountList()
  for (let i = 0; i < teamAccounts.length; i++) {
    const item = teamAccounts[i]
    await syncCompleteTeamTodo(context, item.teamId, false)
  }
  await autoSyncTable(context)
}