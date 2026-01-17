//
//  ExampleView.swift
//  TestAppDemoG
//
//  Created by Yusuf on 17.01.2026.
//

import SwiftUI
import PinterestVLayout

struct Post: Identifiable, Hashable {
    let id: Int
    let title: String
    let body: String
    let color: Color
}

// Section Model
struct PostSection: Identifiable {
    let id = UUID()
    let headerTitle: String
    let items: [Post]
}

class MockDataManager {
    
    static let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .teal]
    static let texts = [
        "Short text.",
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
        "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s.",
        "It has survived not only five centuries, but also the leap into electronic typesetting.",
        "Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. It has survived not only five centuries.",
        "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. It has survived not only five centuries. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. "
    ]
    
    static func generateSingleList(count: Int = 1000) -> [Post] {
        var tempPosts: [Post] = []
        
        for i in 0..<count {
            tempPosts.append(Post(
                id: i,
                title: "Item #\(i + 1)",
                body: texts[i % texts.count],
                color: colors[i % colors.count]
            ))
        }
        return tempPosts
    }
    
    static func generateSectionedList(sectionCount: Int = 5, itemsPerSection: Int = 10) -> [PostSection] {
        var sections: [PostSection] = []
        var globalIDCounter = 0
        
        for s in 0..<sectionCount {
            var sectionPosts: [Post] = []
            
            for i in 0..<itemsPerSection {
                sectionPosts.append(Post(
                    id: globalIDCounter,
                    title: "Section \(s+1) - Item #\(i+1)",
                    body: texts[globalIDCounter % texts.count],
                    color: colors[globalIDCounter % colors.count]
                ))
                globalIDCounter += 1
            }
            
            let newSection = PostSection(
                headerTitle: "Section \(s + 1)",
                items: sectionPosts
            )
            sections.append(newSection)
        }
        
        return sections
    }
}

struct PostListView: View {
    @State private var posts: [Post] = []
    @State private var allData: [Post] = []
    @State var isLoading = false

    init() {
        let data = MockDataManager.generateSingleList(count: 200)
        _allData = State(initialValue: data)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                PinterestGrid(
                    data: posts,
                    columns: 4,
                    spacing: 10,
                    isLoading: isLoading,
                    onLoadMore: { loadNextPage() }
                ) { post in
                    PostCardView(post: post).onTapGesture {
                        print("Test.. \(post.title)")
                    }
                }
                .padding(.horizontal, 4)
                
                if isLoading {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(.bottom, 10)
                }
            }
            .navigationTitle("Single List")
            .onAppear { if posts.isEmpty { loadNextPage() } }
        }
    }
    
    func loadNextPage() {
        guard !isLoading else { return }
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            let start = posts.count
            let end = min(start + 30, allData.count)
            if start < end {
                let nextBatch = allData[start..<end]
                self.posts.append(contentsOf: nextBatch)
            }
            self.isLoading = false
        }
    }
}

struct PostCardView: View {
    let post: Post
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title).font(.headline).bold()
            Text(post.body).font(.subheadline).foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(post.color.opacity(0.12))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(post.color.opacity(0.3), lineWidth: 1))
    }
}


struct PostSectionListView: View {
    @State private var sections: [PinterestGridSection<Post>]

    init() {
        let rawData = MockDataManager.generateSectionedList(sectionCount: 20, itemsPerSection: 8)
        let formattedData = rawData.map { section in
            PinterestGridSection(
                id: section.id,
                contentView: VStack(alignment: .leading, spacing: 4) {
                    Text(section.headerTitle)
                        .font(.title3.bold())
                        .padding(.top, 12)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 40, height: 4)
                        .cornerRadius(2)
                }
                .padding(.vertical, 8)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red),
                items: section.items
            )
        }
        
        _sections = State(initialValue: formattedData)
    }
    
    var body: some View {
        PinterestGrid(
            sections: sections,
            columns: 2,
            spacing: 12
        ) { post in
            PostCardView(post: post)
        } header: { section in
            EmptyView()
        }
    }
}
