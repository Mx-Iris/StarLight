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
    var repository: Repository

    var body: some View {
        HStack(spacing: 10) {
            WebImage(
                url: repository.owner?.avatarURL,
                content: { image in
                    image
                        .resizable()
                        .frame(maxWidth: 30, maxHeight: 30)
                        .cornerRadius(5)
                },
                placeholder: {
                    ProgressView()
                }
            )
            .frame(maxWidth: 30, maxHeight: 30)
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(repository.fullname)
                        .font(.system(size: 14))
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
                if Defaults[.showRepositoryDescription] {
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
