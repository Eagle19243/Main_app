var data = [
  { id: '1', title: 'Description'},
  { id: '2', title: 'Tasks' },
  { id: '3', title: 'NewsFeed' },
  { id: '4', title: 'Publish' }
]

/* Tabs Component Base using Foundation */

var Tabs = React.createClass({
  getInitialState: function () {
    return {activeTab: 0}
  },
  handleClick: function(index) {
    this.setState({activeTab: index})
    return false
  },
  render: function () {

    var logedIn = this.props.signInStatus;
    var projectOwner = this.props.projectOwner;
    var project_id = this.props.project.id
    var user_id = this.props.projectUser.id

      if (logedIn) {
        if (projectOwner){
          var editButton = <a href={'/projects/'+project_id+'/edit'} id="editBtn" name="editBtn" className="button tiny radius margin-button">Edit</a>
        } //Inner If condition closed
      } //If condition closed

      if(this.props.project.institution_name){
        var institue =  (<span> {', ' + this.props.project.institution_name}</span>)
      }

    return (
      <div className="top-margin">
        <dl className="tabs tabs-center">
        {this.props.data.map(function (tab, index) {
            var activeClass = this.state.activeTab === index ? 'active' : ''
            return (
              <dd className={'tab ' + activeClass} key={tab.id} id={tab.id} >
                <a href={'#' + tab.title} onClick={this.handleClick.bind(this, index)}>{tab.title}</a>
              </dd>
            )
          }, this)}
        </dl>

        <div className="tabs-content">

        {this.props.data.map(function (tab, index) {
          var activeClass = this.state.activeTab === index ? 'active' : ''

          if (tab.title === 'Description'){
            return (

              <div className={'content ' + activeClass} key={tab.id} >
                <div className="admin-info">
                Created by: <a href={'/users/'+user_id}>{this.props.projectUser.name}</a> {institue}
                  <div className="prof-pic"></div>
                </div>
                  <div className="project-show-description" data-edit-alert="true">
                      <p id="proj-desc">{this.props.project.description}</p>
                      {editButton}
                  </div>
              </div>

                /* Last Portion of this Section is Left */

            )
          } // Description if Closed
         else if (tab.title === 'Tasks'){
            return (
              <div className={'content ' + activeClass + ' center'} key={tab.id} >
                <span>Task Panel will Be Displayed Here.</span>
              </div>
            )
          } // Tasks if Closed

          else if (tab.title === 'NewsFeed'){
             return (
               <div className={'content ' + activeClass + ' center'} key={tab.id} >
                 <span>News Feed will Be Displayed Here.</span>
               </div>
             )
           } // Taks if Closed

           else if (tab.title === 'Publish'){
              return (
                <div className={'content ' + activeClass + ' center'} key={tab.id} >
                  <span>Publish Section will Be Displayed Here.</span>
                </div>
              )
            } // Taks if Closed

        },this)}
        </div>
      </div> //Top Margin Closed
    ) //Return Close
  } // Render Function CLoosee
}) // CLass closed

/*  Main Entry Point of the React Component. */

var ProjectData = React.createClass({
  getInitialState: function() {
    console.log("initial");
    return {project_selected: this.props.project, projectuser: this.props.project_user,
            userSignedIn: this.props.userSignedIn, projectOwner: this.props.projectOwner}
  },
  render: function () {
    console.log("render");
      return (
        <Tabs data={data} project={this.state.project_selected} projectUser={this.state.projectuser}
          signInStatus={this.state.userSignedIn} projectOwner={this.state.projectOwner} />
      )
  }
})
