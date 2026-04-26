import { util } from '@kit.ArkTS'
import { TodoItem } from './Dataimport'

function timeStampToIcsTimeString(timeStamp: number) {
  const date = new Date(timeStamp)
  return date.getUTCFullYear() + String(date.getUTCMonth() + 1).padStart(2, '0') +
    String(date.getUTCDate()).padStart(2, '0') + 'T' + String(date.getUTCHours()).padStart(2, '0') +
    String(date.getUTCMinutes()).padStart(2, '0') + String(date.getUTCSeconds()).padStart(2, '0') + 'Z'
}

function icsTimeStringToTimeStamp(icsTimeString: string) {
  if (icsTimeString[15] === 'Z') {
    return new Date(Date.UTC(Number(icsTimeString.substring(0, 4)), Number(icsTimeString.substring(4, 6)) - 1,
      Number(icsTimeString.substring(6, 8)), Number(icsTimeString.substring(9, 11)),
      Number(icsTimeString.substring(11, 13)), Number(icsTimeString.substring(13, 15)))).getTime()
  }
  return new Date(Number(icsTimeString.substring(0, 4)), Number(icsTimeString.substring(4, 6)) - 1,
    Number(icsTimeString.substring(6, 8)), Number(icsTimeString.substring(9, 11)),
    Number(icsTimeString.substring(11, 13)), Number(icsTimeString.substring(13, 15))).getTime()
}

export function icsstringify(todoArray: TodoItem[]) {
  let result = ''
  result += 'BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'
  todoArray.forEach(item => {
    result += 'BEGIN:VEVENT\r\n'
    result += 'UID:' + item.id + '\r\n'
    result += 'SUMMARY:' + item.content + '\r\n'
    result += 'PRIORITY:' + item.priority + '\r\n'
    result += 'DTSTART:' + timeStampToIcsTimeString(item.startTime) + '\r\n'
    if (item.endTime !== -1) {
      result += 'DTEND:' + timeStampToIcsTimeString(item.endTime) + '\r\n'
    }
    if (item.recurrenceRule) {
      result += 'RRULE:' + item.recurrenceRule + '\r\n'
    }
    if (item.excludeTime.length > 0) {
      result += 'EXDATE:' + item.excludeTime.map((item): string => timeStampToIcsTimeString(item)).join(',') + '\r\n'
    }
    if (item.tag.length > 0) {
      result += 'CATEGORIES:' + item.tag.join(',') + '\r\n'
    }
    if (item.location.latitude !== -1 && item.location.longitude !== -1) {
      result += 'GEO:' + item.location.latitude + ';' + item.location.longitude + '\r\n'
    }
    if (item.location.desc) {
      result += 'LOCATION:' + item.location.desc + '\r\n'
    }
    if (item.bz) {
      result += 'DESCRIPTION:' + item.bz + '\r\n'
    }
    if (item.recentCompletedTime !== -1) {
      result += 'COMPLETED:' + timeStampToIcsTimeString(item.recentCompletedTime) + '\r\n'
    }
    result += 'LAST-MODIFIED:' + timeStampToIcsTimeString(item.updateTime) + '\r\n'
    result += 'END:VEVENT\r\n'
  })
  result += 'END:VCALENDAR'
  return result
}

export function icsparse(icsString: string) {
  const rows = icsString.split('\r\n')
  const result: TodoItem[] = []
  let todo: TodoItem = {
    id: util.generateRandomUUID(),
    content: '',
    priority: 5,
    startTime: Date.now(),
    endTime: -1,
    duration: -1,
    recurrenceRule: '',
    excludeTime: [],
    tag: [],
    dependency: [],
    location: {
      latitude: -1,
      longitude: -1,
      desc: ''
    },
    action: [],
    bz: '',
    recentCompletedTime: -1,
    updateTime: Date.now(),
    cloudBackupTime: []
  }
  let begin = false
  rows.forEach(item => {
    if (item === 'BEGIN:VEVENT') {
      begin = true
      todo = {
        id: util.generateRandomUUID(),
        content: '',
        priority: 5,
        startTime: Date.now(),
        endTime: -1,
        duration: -1,
        recurrenceRule: '',
        excludeTime: [],
        tag: [],
        dependency: [],
        location: {
          latitude: -1,
          longitude: -1,
          desc: ''
        },
        action: [],
        bz: '',
        recentCompletedTime: -1,
        updateTime: Date.now(),
        cloudBackupTime: []
      }
    }
    if (item === 'END:VEVENT') {
      begin = false
      result.push(todo)
    }
    if (begin) {
      const keyValue = item.split(':', 2)
      if (keyValue.length === 2) {
        const key = keyValue[0]
        const value = keyValue[1]
        if (key === 'UID') {
          todo.id = value
        }
        if (key === 'SUMMARY') {
          todo.content = value
        }
        if (key === 'PRIORITY') {
          todo.priority = Number(value)
        }
        if (key === 'DTSTART') {
          todo.startTime = icsTimeStringToTimeStamp(value)
        }
        if (key === 'DTEND') {
          todo.endTime = icsTimeStringToTimeStamp(value)
        }
        if (key === 'RRULE') {
          todo.recurrenceRule = value
        }
        if (key === 'EXDATE') {
          todo.excludeTime = value.split(',').map((item): number => icsTimeStringToTimeStamp(item))
        }
        if (key === 'CATEGORIES') {
          todo.tag = value.split(',')
        }
        if (key === 'GEO') {
          const geo = value.split(';')
          todo.location.latitude = Number(geo[0])
          todo.location.longitude = Number(geo[1])
        }
        if (key === 'LOCATION') {
          todo.location.desc = value
        }
        if (key === 'DESCRIPTION') {
          todo.bz = value
        }
        if (key === 'COMPLETED' && value) {
          todo.recentCompletedTime = icsTimeStringToTimeStamp(value)
        }
        if (key === 'LAST-MODIFIED') {
          todo.updateTime = icsTimeStringToTimeStamp(value)
        }
      }
    }
  })
  return result
}