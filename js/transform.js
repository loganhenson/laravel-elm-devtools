const transform = (data) => {
  for (let key in data) {
    if (! data.hasOwnProperty(key)) {
      continue
    }
    console.log('_', data[key])

    if (data[key].hasOwnProperty('value')) {
      if (data[key].hasOwnProperty('name') && data[key].name === 'Just') {
        data[key] = `Just ${transform(data[key].value)}`
      } else {
        data[key] = transform(data[key].value)
      }
    } else if (data[key].hasOwnProperty('name')) {
      data[key] = data[key].name
    }
  }

  return data
}

export default transform
