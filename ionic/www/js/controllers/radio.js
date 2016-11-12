angular.module('app.controllers')

.controller('RadioCtrl', ['$scope', '$http', function($scope, serviceLog, $ionicPopup, $timeout) {
  console.log('RadioCtrl');

  var fb_url = localStorage.getItem('firebase_url');
  if (fb_url != null) {

    $scope.pushCtrl0 = {
      checked: false
    };

    $scope.InactiveRadioCodes = [];
    $scope.ActiveRadioCodes = [];

    // remove radio code
    $scope.RemoveInactiveRadioCode = function(i) {
      $scope.InactiveRadioCodes.splice(i, 1);
    };

    // move radio code to active
    $scope.ActivateRadioCode = function(i) {
      $scope.ActiveRadioCodes.push($scope.InactiveRadioCodes[i]);
      $scope.InactiveRadioCodes.splice(i, 1);
    };

    // remove radio code
    $scope.RemoveActiveRadioCode = function(i) {
      $scope.ActiveRadioCodes.splice(i, 1);
    };

    // move radio code to inactive
    $scope.DeactivateRadioCode = function(i) {
      $scope.InactiveRadioCodes.push($scope.ActiveRadioCodes[i]);
      $scope.ActiveRadioCodes.splice(i, 1);
    };

    $scope.SetupRadio = function() {
      var ref = firebase.database().ref("RadioCodes");
      ref.child('Active').remove();
      console.log('active');
      $scope.ActiveRadioCodes.forEach(function(element) {
        console.log(element.val());
        ref.child('Active').push().set(element.val());
      });
      ref.child('Inactive').remove();
      console.log('inactive');
      $scope.InactiveRadioCodes.forEach(function(element) {
        console.log(element.val());
        ref.child('Inactive').push().set(element.val());
      });
    }

    $scope.pushCtrl0Change = function() {
      var ref = firebase.database().ref("control");
      serviceLog.putlog('radio_learn control ' + $scope.pushCtrl0.checked);
      if ($scope.pushCtrl0.checked) {
        ref.update({
          radio_learn: true
        });
      } else {
        ref.update({
          radio_learn: false
        });
      }
    };

    $scope.doRefresh = function() {
      console.log('doRefresh');

      var ref_inactive = firebase.database().ref('RadioCodes/Inactive');
      var i = 0;
      $scope.InactiveRadioCodes = [];
      ref_inactive.once('value', function(snapshot) {
        snapshot.forEach(function(childSnapshot) {
          // console.log(childSnapshot.val());
          $scope.InactiveRadioCodes.push(childSnapshot);
          i++;
        });
      });

      var ref_active = firebase.database().ref('RadioCodes/Active');
      var i = 0;
      $scope.ActiveRadioCodes = [];
      ref_active.once('value', function(snapshot) {
        snapshot.forEach(function(childSnapshot) {
          // console.log(childSnapshot.val());
          $scope.ActiveRadioCodes.push(childSnapshot);
          i++;
        });
      });

      var ref = firebase.database().ref("control/radio_learn");
      // Attach an asynchronous callback to read the data at our posts reference
      ref.on('value', function(snapshot) {
        var payload = snapshot.val();

        if (payload == true) {
          $scope.pushCtrl0.checked = true;
        } else {
          $scope.pushCtrl0.checked = false;
        }
      }, function(errorObject) {
        serviceLog.putlog("firebase failed: " + errorObject.code);
      });

      // $scope.$broadcast("scroll.infiniteScrollComplete");
      $scope.$broadcast('scroll.refreshComplete');
    };
  }
}]);