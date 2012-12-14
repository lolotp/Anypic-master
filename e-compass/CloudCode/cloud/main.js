Parse.Cloud.beforeSave('Activity', function(request, response) {
  var currentUser = Parse.User.current(); 
  var objectUser = request.object.get('fromUser');

  if(!currentUser || !objectUser) {
    response.error('An Activity should have a valid fromUser.');
  } else if (currentUser.id === objectUser.id) {
    response.success();
  } else {
    response.error('Cannot set fromUser on Activity to a user other than the current user.');
  }
});

Parse.Cloud.beforeSave('Photo', function(request, response) {
  var currentUser = Parse.User.current(); 
  var objectUser = request.object.get('user');

  if(!currentUser || !objectUser) {
    response.error('A Photo should have a valid user.');
  } else if (currentUser.id === objectUser.id) {
    response.success();
  } else {
    response.error('Cannot set user on Photo to a user other than the current user.');
  }
});
