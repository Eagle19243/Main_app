@AlertBox = React.createClass
  getInitialState: ->
    id: @props.id

  hideAlertBox: (e) ->
    e.preventDefault()
    $('#'+@state.id).parent().hide()

  render: ->
    React.DOM.div
      style: {"display": "none", "margin-bottom" : "10px"}
      ref: "hope"
      className: "alert-box round alert"
      React.DOM.div
        id: @state.id
      React.DOM.a
        className: "close"
        onClick: @hideAlertBox
        href: '#'
        '×'