import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { getPersonalAccountInfo } from './Account'
import { Action, Location } from './Datachange'
import { TodoItem } from './Dataimport'
import { getRecentTodoFromFreq } from './Rrule'

export interface CloudBackupTimeItem {
  uid: string,
  time: number
}

export interface Todo {
  id: string,
  teamId: string,
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
  isCompleted?: boolean,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[],
  isCloudBackup: boolean
}

export async function isTodoCompleted(context: Context, id: string, currentTime: number) {
  const info = await getTodoInfo(context, id)
  if (info !== 'fail') {
    if (!info.recurrenceRule && info.recentCompletedTime !== -1) {
      return true
    }
    if (info.recurrenceRule) {
      const recentTodoStartEndTime =
        getRecentTodoFromFreq(context, info.recurrenceRule, info.startTime, info.endTime, info.excludeTime, currentTime)
      if (info.recentCompletedTime >= recentTodoStartEndTime.startTime) {
        return true
      }
    }
  }
  return false
}

export async function getTodoInfo(context: Context, id: string) {
  const rdbStore = await relationalStore.getRdbStore(context, {
    name: 'todo',
    securityLevel: relationalStore.SecurityLevel.S1,
    encrypt: true,
    allowRebuild: true
  })
  const predicates = new relationalStore.RdbPredicates('todo')
  predicates.equalTo('id', id)
  const resultSet = await rdbStore.query(predicates)
  const idIndex = resultSet.getColumnIndex('id')
  const teamIdIndex = resultSet.getColumnIndex('teamId')
  const contentIndex = resultSet.getColumnIndex('content')
  const priorityIndex = resultSet.getColumnIndex('priority')
  const startTimeIndex = resultSet.getColumnIndex('startTime')
  const endTimeIndex = resultSet.getColumnIndex('endTime')
  const durationIndex = resultSet.getColumnIndex('duration')
  const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
  const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
  const tagIndex = resultSet.getColumnIndex('tag')
  const dependencyIndex = resultSet.getColumnIndex('dependency')
  const locationIndex = resultSet.getColumnIndex('location')
  const actionIndex = resultSet.getColumnIndex('action')
  const bzIndex = resultSet.getColumnIndex('bz')
  const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
  const updateTimeIndex = resultSet.getColumnIndex('updateTime')
  const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
  if (resultSet.goToNextRow()) {
    const info: Todo = {
      id: resultSet.getValue(idIndex) as string,
      teamId: resultSet.getValue(teamIdIndex) as string,
      content: resultSet.getValue(contentIndex) as string,
      priority: resultSet.getValue(priorityIndex) as number,
      startTime: resultSet.getValue(startTimeIndex) as number,
      endTime: resultSet.getValue(endTimeIndex) as number,
      duration: resultSet.getValue(durationIndex) as number,
      recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
      excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
      tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
      dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
      location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
      action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
      bz: resultSet.getValue(bzIndex) as string,
      recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
      updateTime: resultSet.getValue(updateTimeIndex) as number,
      cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[],
      isCloudBackup: false
    }
    resultSet.close()
    const accountInfo = await getPersonalAccountInfo()
    const cloudBackupTimeItem = info.cloudBackupTime.find(item => item.uid === accountInfo.uid)
    if (cloudBackupTimeItem) {
      if (cloudBackupTimeItem.time >= info.updateTime) {
        info.isCloudBackup = true
      }
    }
    return info
  }
  resultSet.close()
  return 'fail'
}

export async function getTodoList(context: Context, currentTime: number) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('todo')
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const teamIdIndex = resultSet.getColumnIndex('teamId')
    const contentIndex = resultSet.getColumnIndex('content')
    const priorityIndex = resultSet.getColumnIndex('priority')
    const startTimeIndex = resultSet.getColumnIndex('startTime')
    const endTimeIndex = resultSet.getColumnIndex('endTime')
    const durationIndex = resultSet.getColumnIndex('duration')
    const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
    const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
    const tagIndex = resultSet.getColumnIndex('tag')
    const dependencyIndex = resultSet.getColumnIndex('dependency')
    const locationIndex = resultSet.getColumnIndex('location')
    const actionIndex = resultSet.getColumnIndex('action')
    const bzIndex = resultSet.getColumnIndex('bz')
    const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: Todo[] = []
    while (resultSet.goToNextRow()) {
      const info: Todo = {
        id: resultSet.getValue(idIndex) as string,
        teamId: resultSet.getValue(teamIdIndex) as string,
        content: resultSet.getValue(contentIndex) as string,
        priority: resultSet.getValue(priorityIndex) as number,
        startTime: resultSet.getValue(startTimeIndex) as number,
        endTime: resultSet.getValue(endTimeIndex) as number,
        duration: resultSet.getValue(durationIndex) as number,
        recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
        excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
        tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
        dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
        location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
        action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
        bz: resultSet.getValue(bzIndex) as string,
        recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
        isCompleted: await isTodoCompleted(context, resultSet.getValue(idIndex) as string, currentTime),
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[],
        isCloudBackup: false
      }
      const accountInfo = await getPersonalAccountInfo()
      const cloudBackupTimeItem = info.cloudBackupTime.find(item => item.uid === accountInfo.uid)
      if (cloudBackupTimeItem) {
        if (cloudBackupTimeItem.time >= info.updateTime) {
          info.isCloudBackup = true
        }
      }
      array.push(info)
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getPersonalTodoList(context: Context) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('todo')
    predicates.equalTo('teamId', '')
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const contentIndex = resultSet.getColumnIndex('content')
    const priorityIndex = resultSet.getColumnIndex('priority')
    const startTimeIndex = resultSet.getColumnIndex('startTime')
    const endTimeIndex = resultSet.getColumnIndex('endTime')
    const durationIndex = resultSet.getColumnIndex('duration')
    const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
    const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
    const tagIndex = resultSet.getColumnIndex('tag')
    const dependencyIndex = resultSet.getColumnIndex('dependency')
    const locationIndex = resultSet.getColumnIndex('location')
    const actionIndex = resultSet.getColumnIndex('action')
    const bzIndex = resultSet.getColumnIndex('bz')
    const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: TodoItem[] = []
    while (resultSet.goToNextRow()) {
      array.push({
        id: resultSet.getValue(idIndex) as string,
        content: resultSet.getValue(contentIndex) as string,
        priority: resultSet.getValue(priorityIndex) as number,
        startTime: resultSet.getValue(startTimeIndex) as number,
        endTime: resultSet.getValue(endTimeIndex) as number,
        duration: resultSet.getValue(durationIndex) as number,
        recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
        excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
        tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
        dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
        location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
        action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
        bz: resultSet.getValue(bzIndex) as string,
        recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
        updateTime: resultSet.getValue(updateTimeIndex) as number,
        cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
      })
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export async function getFilterTodoList(context: Context, currentTime: number, contentKeyword: string, tag: string[]) {
  try {
    const rdbStore = await relationalStore.getRdbStore(context, {
      name: 'todo',
      securityLevel: relationalStore.SecurityLevel.S1,
      encrypt: true,
      allowRebuild: true
    })
    const predicates = new relationalStore.RdbPredicates('todo')
    if (contentKeyword) {
      predicates.contains('content', contentKeyword)
    }
    const resultSet = await rdbStore.query(predicates)
    const idIndex = resultSet.getColumnIndex('id')
    const teamIdIndex = resultSet.getColumnIndex('teamId')
    const contentIndex = resultSet.getColumnIndex('content')
    const priorityIndex = resultSet.getColumnIndex('priority')
    const startTimeIndex = resultSet.getColumnIndex('startTime')
    const endTimeIndex = resultSet.getColumnIndex('endTime')
    const durationIndex = resultSet.getColumnIndex('duration')
    const recurrenceRuleIndex = resultSet.getColumnIndex('recurrenceRule')
    const excludeTimeIndex = resultSet.getColumnIndex('excludeTime')
    const tagIndex = resultSet.getColumnIndex('tag')
    const dependencyIndex = resultSet.getColumnIndex('dependency')
    const locationIndex = resultSet.getColumnIndex('location')
    const actionIndex = resultSet.getColumnIndex('action')
    const bzIndex = resultSet.getColumnIndex('bz')
    const recentCompletedTimeIndex = resultSet.getColumnIndex('recentCompletedTime')
    const updateTimeIndex = resultSet.getColumnIndex('updateTime')
    const cloudBackupTimeIndex = resultSet.getColumnIndex('cloudBackupTime')
    const array: Todo[] = []
    while (resultSet.goToNextRow()) {
      let fit = true
      if (tag.length > 0) {
        const todoTag = JSON.parse(resultSet.getValue(tagIndex) as string) as string[]
        fit = tag.every(item => todoTag.includes(item))
      }
      if (fit) {
        const info: Todo = {
          id: resultSet.getValue(idIndex) as string,
          teamId: resultSet.getValue(teamIdIndex) as string,
          content: resultSet.getValue(contentIndex) as string,
          priority: resultSet.getValue(priorityIndex) as number,
          startTime: resultSet.getValue(startTimeIndex) as number,
          endTime: resultSet.getValue(endTimeIndex) as number,
          duration: resultSet.getValue(durationIndex) as number,
          recurrenceRule: resultSet.getValue(recurrenceRuleIndex) as string,
          excludeTime: JSON.parse(resultSet.getValue(excludeTimeIndex) as string) as number[],
          tag: JSON.parse(resultSet.getValue(tagIndex) as string) as string[],
          dependency: JSON.parse(resultSet.getValue(dependencyIndex) as string) as string[],
          location: JSON.parse(resultSet.getValue(locationIndex) as string) as Location,
          action: JSON.parse(resultSet.getValue(actionIndex) as string) as Action[],
          bz: resultSet.getValue(bzIndex) as string,
          recentCompletedTime: resultSet.getValue(recentCompletedTimeIndex) as number,
          isCompleted: await isTodoCompleted(context, resultSet.getValue(idIndex) as string, currentTime),
          updateTime: resultSet.getValue(updateTimeIndex) as number,
          cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[],
          isCloudBackup: false
        }
        const accountInfo = await getPersonalAccountInfo()
        const cloudBackupTimeItem = info.cloudBackupTime.find(item => item.uid === accountInfo.uid)
        if (cloudBackupTimeItem) {
          if (cloudBackupTimeItem.time >= info.updateTime) {
            info.isCloudBackup = true
          }
        }
        array.push(info)
      }
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code
    })
    return []
  }
}

export function getRecommendTodoList() {
  return []
}