//
//  MainActionBarCellView.swift
//  StarLight
//
//  Created by JH on 2025/1/22.
//

import SwiftUI
import GitHubModels
import SDWebImageSwiftUI
import StarLightResources
import Defaults

struct MainActionBarCellView: View {
    /// The point size the owner avatar is drawn at.
    private static let avatarSideLength: CGFloat = 30

    /// GitHub serves avatars at 460x460, and scaling that down to `avatarSideLength` in a single
    /// drawing pass aliases badly on detailed icons. Decoding a thumbnail first hands the renderer
    /// a source only a couple of times larger than the destination, which samples down cleanly.
    private static let avatarThumbnailPixelSize = CGSize(width: 120, height: 120)

    var repository: Repository

    @Default(.showRepositoryDescription)
    var showRepositoryDescription

    var body: some View {
        HStack(spacing: 10) {
            WebImage(
                url: repository.owner?.avatarURL,
                context: [.imageThumbnailPixelSize: Self.avatarThumbnailPixelSize],
                content: { image in
                    image
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(5)
                },
                placeholder: {
                    ProgressView()
                        .controlSize(.regular)
                }
            )
            .frame(width: Self.avatarSideLength, height: Self.avatarSideLength)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(repository.fullname)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.leading)
                    if repository.isPrivate {
                        Assets.Octicons.lock16.swiftUIImage
                            .foregroundColor(.secondary)
                            .help("Private repository")
                    }
                    Spacer()
                }
                if showRepositoryDescription {
                    HStack {
                        Text(repository.description ?? "No description")
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondary)
                            .font(.callout)
                        Spacer()
                    }
                }
                HStack(spacing: 15) {
                    if let programmingLanguage = repository.programmingLanguage {
                        HStack(spacing: 5) {
                            Circle()
                                .frame(width: 10, height: 10)
                                .foregroundColor(Color(nsColor: programmingLanguage.color?.nsColor ?? .white))
                            Text(programmingLanguage.rawValue)
                                .font(.callout)
                        }
                    }
                    HStack(spacing: 5) {
                        Assets.Octicons.star16.swiftUIImage
                            .foregroundColor(.secondary)
                        Text(repository.stargazersCount.string)
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                    HStack(spacing: 5) {
                        Assets.Octicons.repoForked16.swiftUIImage
                            .foregroundColor(.secondary)
                        Text(repository.forksCount.string)
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                }
            }
        }
        .padding(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
    }
}

#Preview {
    MainActionBarCellView(repository: .testModel)
}
