//
//  RedditClientTests.swift
//  RedditClientTests
//
//  Created by Anton Voitsekhivskyi on 10/27/19.
//  Copyright © 2019 AVoitsekhivskyi. All rights reserved.
//

import XCTest
@testable import RedditClient

class RedditPostTests: XCTestCase {

    override func setUp() { }

    override func tearDown() { }

    func testDecodingFullJson() {
        // GIVEN - Well-formed JSON
        let testBundle = Bundle(for: type(of: self))
        let jsonData = try! Data(contentsOf: testBundle.url(forResource: "TestRedditPostFull", withExtension: "json")!)

        // WHEN - creating RedditPost model
        let redditPost = try? JSONDecoder().decode(RedditPost.self, from: jsonData)
        
        // THEN - all field should be parsed correctly
        checkRequiredFields(redditPost: redditPost)
        XCTAssertEqual(redditPost?.thumbnailURL, URL(string: "https://b.thumbs.redditmedia.com/UA1U7O06n2X184An6FHWP1104-p8Au42sBIc7sr0EMQ.jpg"))
        XCTAssertEqual(redditPost?.commentsCount, 3)
        XCTAssertEqual(redditPost?.originalImageURL, URL(string:"https://external-preview.redd.it/deG9vkSeXegIMWYTRu_sZxy6_PeAf_aLcetMbnwMJ4k.jpg?auto=webp&amp;s=c6e3fa61dc2af3f2e3bb1bebd6169b574b0b57b7"))
    }
    
    func testDecodingInvalidJson() {
        // GIVEN - JSON with no name(id) of the post
        let testBundle = Bundle(for: type(of: self))
        
        // WHEN - creating RedditPost model
        let jsonData = try! Data(contentsOf: testBundle.url(forResource: "TestRedditPostInvalid", withExtension: "json")!)
        let redditPost = try? JSONDecoder().decode(RedditPost.self, from: jsonData)
        
        // THEN - RedditPost model creation fails
        XCTAssertNil(redditPost, "No name/id-post is considered as invalid")
    }

    func testDecodingNoCommentsJson() {
        // GIVEN - JSON with no comments count available post
        let testBundle = Bundle(for: type(of: self))
        let jsonData = try! Data(contentsOf: testBundle.url(forResource: "TestRedditPostNoComments", withExtension: "json")!)
        
        // WHEN - creating RedditPost model
        let redditPost = try? JSONDecoder().decode(RedditPost.self, from: jsonData)
        
        
        // THEN - Zero as the default value for comments count is set. Rest fields are parsed normally
        XCTAssertEqual(redditPost?.commentsCount, 0, "Zero count should be specified for comments count")
        checkRequiredFields(redditPost: redditPost)
        XCTAssertEqual(redditPost?.thumbnailURL, URL(string: "https://b.thumbs.redditmedia.com/UA1U7O06n2X184An6FHWP1104-p8Au42sBIc7sr0EMQ.jpg"))
        XCTAssertEqual(redditPost?.originalImageURL, URL(string:"https://external-preview.redd.it/deG9vkSeXegIMWYTRu_sZxy6_PeAf_aLcetMbnwMJ4k.jpg?auto=webp&amp;s=c6e3fa61dc2af3f2e3bb1bebd6169b574b0b57b7"))
    }

    func testDecodingNoThumbnailJson() {
        // GIVEN - JSON with no thumbnail image URL available
        let testBundle = Bundle(for: type(of: self))
        let jsonData = try! Data(contentsOf: testBundle.url(forResource: "TestRedditPostNoThumbnail", withExtension: "json")!)
        
        // WHEN - creating RedditPost model
        let redditPost = try? JSONDecoder().decode(RedditPost.self, from: jsonData)
        
        // THEN - Nil for thumbnailURL is set. Rest fields are parsed normally
        checkRequiredFields(redditPost: redditPost)
        XCTAssertEqual(redditPost?.commentsCount, 3)
        XCTAssertNil(redditPost?.thumbnailURL)
        XCTAssertEqual(redditPost?.originalImageURL, URL(string:"https://external-preview.redd.it/deG9vkSeXegIMWYTRu_sZxy6_PeAf_aLcetMbnwMJ4k.jpg?auto=webp&amp;s=c6e3fa61dc2af3f2e3bb1bebd6169b574b0b57b7"))
    }

    func testDecodingNoOriginalImageJson() {
        // GIVEN - JSON with no original image URL available
        let testBundle = Bundle(for: type(of: self))
        let jsonData = try! Data(contentsOf: testBundle.url(forResource: "TestRedditPostNoOriginalImage", withExtension: "json")!)
        
        // WHEN - creating RedditPost model
        let redditPost = try? JSONDecoder().decode(RedditPost.self, from: jsonData)
        
        // THEN - Nil for originalImage is set. Rest fields are parsed normally
        checkRequiredFields(redditPost: redditPost)
        XCTAssertEqual(redditPost?.commentsCount, 3)
        XCTAssertEqual(redditPost?.thumbnailURL, URL(string: "https://b.thumbs.redditmedia.com/UA1U7O06n2X184An6FHWP1104-p8Au42sBIc7sr0EMQ.jpg"))
        XCTAssertNil(redditPost?.originalImageURL)
    }
    
    // MARK: - Helpers
    func checkRequiredFields(redditPost: RedditPost?) {
        XCTAssertEqual(redditPost?.id, "t3_testid")
        XCTAssertEqual(redditPost?.title, "Test Title")
        XCTAssertEqual(redditPost?.author, "TestAuthorName")
        XCTAssertEqual(redditPost?.dateCreated, Date(timeIntervalSince1970: 1554763977.0))
        XCTAssertFalse(redditPost?.hidden ?? true)
    }
}
