NodeList.prototype.toArray = function () {
  return Array.from(this)
}

document.querySelectorAll("select").toArray().forEach(select => {
  let value = select.getAttribute("value")
  if (value != null)
    select.value = value
})