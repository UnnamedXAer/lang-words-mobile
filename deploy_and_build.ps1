#install
# Connect your Android device to your computer with a USB cable.
# Enter cd [project].
# Run flutter install.


# example:
#  "🔢 Update version number"; code pubspec.yaml;
# ./deploy_and_build --release

param ($buildType = 'release', $flavor = 'staging', [switch]$buildAssets = $false)

$availableFlavors = @("development", "staging", "production")
$availableBuildTypes = @("release", "profile", "debug")
$mainFileDir;
$firebaseProject;
$apkDir;

if ($flavor -eq $null -or $flavor -eq "") {
	$flavor = Read-Host -Prompt "Enter flavor, one of $availableFlavors."
}

if ($buildType -eq $null -or $buildType -eq "") {
	$buildType = Read-Host -Prompt "Enter build type, one of $availableBuildTypes."
}



switch ($flavor) {
	"development" {
		$mainFileDir = "main_dev.dart"
		$firebaseProject = "development"
	}
	"staging" {
		$mainFileDir = "main_stag.dart"
		$firebaseProject = "staging"
	}
	"production" {
		$mainFileDir = "main_prod.dart"
		$firebaseProject = "production"
	}
}

if (!$availableBuildTypes.Contains($buildType) -or !$availableFlavors.Contains($flavor)) {

	Write-Host "At least one of parameters is invalid."
	return;
}


Write-Host "Build type: $buildType"
Write-Host "Flavor: $flavor"
Write-Host "Target main file: $mainFileDir"

Write-Host "Getting packages..."
flutter pub get

if ($buildAssets) {
	Write-Host "Generating splash screen..."
	flutter pub run flutter_native_splash:create --flavor $flavor
	Write-Host "Generating launcher icons for $flavor..."
	flutter pub run flutter_launcher_icons:main -f "flutter_launcher_icons-$flavor.yaml"
	Write-Host "Generating ObjectBox code..."
	flutter pub run build_runner build #--delete-conflicting-outputs
}
else {
	Write-Host "Rebuilding assets skipped, pass -buildAssets to trigger rebuilding"
}

try {
	Write-Host "Deploying firebase..."
	# # Select firebase project
	# $res = firebase use $firebaseProject
	# if ($res -contains "Error:") {
	# 	throw $res
	# }
	# Write-Host $res

	# # deploy firebase resources
	# firebase deploy --only database
	# # # firebase deploy  --only ..

	## Write-Host "Firebase deployed."

	# ------------------------------


	# Build apk for Android
	flutter build apk "--$buildType" --flavor $flavor -t "lib/$mainFileDir"

	$apkDir = "build/app/outputs/apk/$flavor/release/app-${flavor}-release.apk"
	Write-Host "Trying to install apk... source: $apkDir"

	adb install $apkDir
}
catch {
	Write-Host "An error occurred:"
	Write-Host $_
	return
}
finally {
	Write-Host "Resetting firebase to use development project..."
	firebase use development
}


