const transform = (data) => {
  for (let key in data) {
    if (! data.hasOwnProperty(key)) {
      continue
    }

    // if (typeof data[key] === 'object' && data[key].hasOwnProperty('value')) {
    //   data[key] = transform(data[key])
    // }

    if (data[key].hasOwnProperty('value')
      && data[key].hasOwnProperty('type')
      && ['List', 'Record'].includes(data[key].type)
    ) {
      // data[key] = transform(data[key].value)
      data[key] = data[key].value
    }

    if (data[key].hasOwnProperty('type')
      && data[key].type === 'String'
      && data[key].hasOwnProperty('type')
    ) {
      data[key] = data[key].value
    }
  }

  return data
}

export default transform
