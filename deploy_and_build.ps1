param ($buildType)

if (!$buildType) {
	$buildType = "--debug"
} elseif ($buildType -eq "--development") {
	$buildType = "--debug"
} elseif ($buildType -eq "--production") {
	$buildType = "--release"
} 

$mainFileDir;
$firebaseProject;
$flavor;

switch ($buildType) {
	"--debug" { 
		$mainFileDir = "main_dev.dart"
		$firebaseProject = "development"
		$flavor = "development"
	}
	"--staging" {
		$mainFileDir = "main_stag.dart"
		$firebaseProject = "staging"
		$flavor = "staging"
		$buildType = "--release"
	}
	"--release" {
		$mainFileDir = "main_prod.dart"
		$firebaseProject = "production"
		$flavor = "production"
	}
	Default {
		throw "invalid build type `"$buildType`""
	}
}

echo "Build type: $buildType"
Write-Host "Flavor: $flavor"
echo "Target main file: $mainFileDir"

Write-Host "Deploying firebase..."
try {
	
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
	flutter build apk $buildType --flavor $flavor -t "lib/$mainFileDir"

	$apkDir = "build/app/outputs/apk/$flavor/release/app-${flavor}-release.apk"

	Write-Host "About to install apk from: $apkDir"
	adb install $apkDir
}
catch {
	Write-Host "An error occurred:"
	Write-Host $_
	return
	<#Do this if a terminating exception happens#>
}
finally {
	# Reset project to development
	firebase use development
}



#install
# Connect your Android device to your computer with a USB cable.
# Enter cd [project].
# Run flutter install.


# example:
#  "🔢 Update version number"; code pubspec.yaml;
# ./deploy_and_build --release