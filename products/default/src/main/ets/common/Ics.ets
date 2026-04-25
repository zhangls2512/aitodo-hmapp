import { Todo } from './Dataget'

function timeStampToIcsTimeString(timeStamp: number) {
  const date = new Date(timeStamp)
  return date.getUTCFullYear() + String(date.getUTCMonth() + 1).padStart(2, '0') +
    String(date.getUTCDate()).padStart(2, '0') + 'T' + String(date.getUTCHours()).padStart(2, '0') +
    String(date.getUTCMinutes()).padStart(2, '0') + String(date.getUTCSeconds()).padStart(2, '0') + 'Z'
}

export function icsstringify(todoArray: Todo[]) {
  let result = ''
  result += 'BEGIN:VCALENDAR\r\nVERSION:2.0\r\n'
  todoArray.forEach(item => {
    result += 'BEGIN:VEVENT\r\n'
    result += 'UID:' + item.id + '\r\n'
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
    if (item.location.desc) {
      result += 'LOCATION:' + item.location.desc + '\r\n'
    }
    if (item.location.latitude && item.location.longitude) {
      result += 'GEO:' + item.location.latitude + ';' + item.location.longitude + '\r\n'
    }
    if (item.bz) {
      result += 'DESCRIPTION:' + item.bz + '\r\n'
    }
    if (item.recentFinishedTime !== -1) {
      result += 'COMPLETED:' + timeStampToIcsTimeString(item.recentFinishedTime) + '\r\n'
    }
    result += 'LAST-MODIFIED:' + timeStampToIcsTimeString(item.updateTime) + '\r\n'
    result += 'END:VEVENT\r\n'
  })
  result += 'END:VCALENDAR'
  return result
}