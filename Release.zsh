# How AppRelease (https://github.com/Mx-Iris/AppRelease) ships StarLight. Pushing a vX.Y tag runs it on
# GitHub Actions (.github/workflows/release.yml); every setting is described in AppRelease's README.
release_engine_version=1.1.1

release_workspace=StarLight.xcworkspace
release_scheme=StarLight
release_archive_arguments=(
    # The project signs automatically, which needs a development certificate; a release is signed
    # with Developer ID from the archive on.
    CODE_SIGN_STYLE=Manual "CODE_SIGN_IDENTITY=Developer ID Application" DEVELOPMENT_TEAM=D5Q73692VW
    # A fresh CI runner has never been asked to trust the macros in the package graph.
    -skipMacroValidation -skipPackagePluginValidation
)
release_product_name='{name}-{tag}.zip'
release_publishers=(github-release)
# Every release ships with notes written beforehand; without them the release stops before anything
# is built.
release_notes_path='ReleaseNotes/{tag}.md'
# Only for a release made on this Mac; CI notarizes with an App Store Connect key.
release_notary_keychain_profile=notarytool-password
