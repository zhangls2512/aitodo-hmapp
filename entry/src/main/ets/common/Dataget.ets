import { relationalStore } from '@kit.ArkData'
import { promptAction } from '@kit.ArkUI'
import { geoLocationManager } from '@kit.LocationKit'
import { map, mapCommon } from '@kit.MapKit'
import { getPersonalAccountInfo, getTeamName } from './Account'
import { Action, canCompleteTodo, Location } from './Datachange'
import { TodoItem } from './Dataimport'
import { getPermission } from './Permission'
import { getFlushPreference } from './Preference'
import { getRecentTodoFromFreq } from './Rrule'
import { getTagMap } from './Tag'

export interface TeamCompleteTimeItem {
  uid: string,
  time: number
}

export interface CloudBackupTimeItem {
  uid: string,
  time: number
}

export interface Todo {
  id: string,
  teamId: string,
  teamName?: string,
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
  recentCompleteTime?: TeamCompleteTimeItem[],
  reviewRecentCompleteTime?: TeamCompleteTimeItem[],
  isCompleted?: boolean,
  canCompleted?: boolean,
  status?: string,
  updateTime: number,
  cloudBackupTime: CloudBackupTimeItem[],
  isCloudBackup?: boolean,
  distance?: number,
  latestStartTime?: number,
  priorityTagScore?: number,
  completeMode?: string,
  allowCompleteUids?: string[],
  allowGetUids?: string[],
  allowReviewUids?: string[]
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
    return false
  }
  return true
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

export async function getCanCompletedTodoList(context: Context, currentTime: number) {
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
        cloudBackupTime: JSON.parse(resultSet.getValue(cloudBackupTimeIndex) as string) as CloudBackupTimeItem[]
      }
      info.teamName = await getTeamName(info.teamId)
      if (info.recurrenceRule) {
        const recentTodoStartEndTime =
          getRecentTodoFromFreq(context, info.recurrenceRule, info.startTime, info.endTime, info.excludeTime,
            currentTime)
        info.startTime = recentTodoStartEndTime.startTime
        info.endTime = recentTodoStartEndTime.endTime
      }
      if (!info.teamId) {
        const canCompleted = await canCompleteTodo(context, info.id, !info.isCompleted, Date.now())
        if (canCompleted) {
          array.push(info)
        }
      }
      if (info.teamId) {
        array.push(info)
      }
    }
    resultSet.close()
    return array
  } catch (err) {
    await promptAction.openToast({
      message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
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
      message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
    })
    return []
  }
}

export async function getCurrentTimePersonalTodoList(context: Context, currentTime: number) {
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
      if (info.recurrenceRule) {
        const recentTodoStartEndTime =
          getRecentTodoFromFreq(context, info.recurrenceRule, info.startTime, info.endTime, info.excludeTime,
            currentTime)
        info.startTime = recentTodoStartEndTime.startTime
        info.endTime = recentTodoStartEndTime.endTime
      }
      info.canCompleted = await canCompleteTodo(context, info.id, !info.isCompleted, Date.now())
      if (currentTime + 86400000 > info.startTime && (info.endTime === -1 || currentTime < info.endTime)) {
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
      message: '发生错误，错误码：' + err.code + (err.message ? '，错误信息：' + err.message : '')
    })
    return []
  }
}

export async function getRecommendTodoList(context: Context) {
  const currentTime = Date.now()
  let list = await getCanCompletedTodoList(context, currentTime)
  const showCompletedTodoInRecommendTodo =
    getFlushPreference(context, 'commonSetting', 'showCompletedTodoInRecommendTodo', false)
  if (!showCompletedTodoInRecommendTodo) {
    list = list.filter(item => !item.isCompleted)
  }
  let latitude = -1
  let longitude = -1
  const location = getPermission('ohos.permission.LOCATION')
  if (location) {
    try {
      const res = await geoLocationManager.getCurrentLocation()
      const gcj02Position = map.convertCoordinateSync(mapCommon.CoordinateType.WGS84, mapCommon.CoordinateType.GCJ02, {
        latitude: res.latitude,
        longitude: res.longitude
      })
      latitude = gcj02Position.latitude
      longitude = gcj02Position.longitude
    } catch {
    }
  }
  list.forEach(item => {
    if (latitude !== -1 && longitude !== -1 && item.location.latitude !== -1 && item.location.longitude !== -1) {
      item.distance = map.calculateDistance({
        latitude: latitude,
        longitude: longitude
      }, {
        latitude: item.location.latitude,
        longitude: item.location.longitude
      })
    } else {
      item.distance = Infinity
    }
  })
  list.forEach(item => {
    if (item.endTime !== -1) {
      if (!item.duration) {
        item.latestStartTime = item.startTime
      }
      if (item.duration) {
        const currentTimeDistance = item.endTime - currentTime
        if (currentTimeDistance > 172800000) {
          item.latestStartTime = Infinity
        }
        if (currentTimeDistance <= 172800000) {
          item.latestStartTime = currentTimeDistance
        }
      }
    }
    if (item.endTime === -1) {
      item.latestStartTime = Infinity
    }
  })
  const tagMap = await getTagMap(context)
  list.forEach(item => {
    let priority = 5
    if (item.priority >= 1 && item.priority <= 9) {
      priority = 10 - item.priority
    }
    let tagScore = 5
    let tagTotalScore = 0
    item.tag.forEach(tagItem => {
      if (!tagMap.has(tagItem)) {
        tagTotalScore += 5
      }
      if (tagMap.has(tagItem)) {
        tagTotalScore += tagMap.get(tagItem) as number
      }
    })
    if (tagTotalScore > 0) {
      tagScore = tagTotalScore / item.tag.length
    }
    item.priorityTagScore = priority * 0.6 + tagScore * 0.4
  })
  return list.sort((a, b) => {
    if (a.distance !== b.distance) {
      return Number(a.distance) - Number(b.distance)
    }
    if (!a.duration || !b.duration) {
      return -1
    }
    if (a.latestStartTime !== b.latestStartTime) {
      return Number(a.latestStartTime) - Number(b.latestStartTime)
    }
    if (a.priorityTagScore !== b.priorityTagScore) {
      return Number(a.priorityTagScore) - Number(b.priorityTagScore)
    }
    return 0
  })
}