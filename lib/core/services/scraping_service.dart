import 'dart:convert';
import 'package:dio/dio.dart';

import '../../../core/services/dio_client.dart';
import '../../../core/constants/api_constants.dart';

/// Scraping service for web content extraction
class ScrapingService {
  final DioClient _dioClient = DioClient();

  /// Scrape a single URL
  Future<ScrapeResult> scrapeUrl(String url, {bool includeImages = true}) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.apiVersion}${ApiConstants.scrapeUrl}',
        data: {
          'url': url,
          'include_images': includeImages,
          'include_links': true,
          'max_content_length': 50000,
        },
      );

      return ScrapeResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Scrape failed: $e');
    }
  }

  /// Scrape multiple URLs (max 10)
  Future<List<ScrapeResult>> scrapeMultiple(List<String> urls) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.apiVersion}${ApiConstants.scrapeUrls}',
        data: {'urls': urls},
      );

      final List results = response.data['results'] ?? [];
      return results.map((r) => ScrapeResult.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Multi-scrape failed: $e');
    }
  }

  /// Search and scrape (DuckDuckGo)
  Future<SearchScrapeResult> searchAndScrape(
    String query, {
    int maxResults = 5,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '${ApiConstants.apiVersion}${ApiConstants.scrapeSearch}',
        data: {
          'query': query,
          'max_results': maxResults,
          'scrape_content': true,
        },
      );

      return SearchScrapeResult.fromJson(response.data);
    } catch (e) {
      throw Exception('Search scrape failed: $e');
    }
  }
}

/// Result from URL scraping
class ScrapeResult {
  final String url;
  final String title;
  final String content;
  final String? summary;
  final List<String> images;
  final List<LinkInfo> links;
  final String? error;
  final bool success;

  ScrapeResult({
    required this.url,
    required this.title,
    required this.content,
    this.summary,
    this.images = const [],
    this.links = const [],
    this.error,
    this.success = true,
  });

  factory ScrapeResult.fromJson(Map<String, dynamic> json) {
    return ScrapeResult(
      url: json['url'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? json['markdown'] ?? '',
      summary: json['summary'],
      images: List<String>.from(json['images'] ?? []),
      links: (json['links'] as List?)
          ?.map((l) => LinkInfo.fromJson(l))
          .toList() ?? [],
      error: json['error'],
      success: json['success'] ?? json['error'] == null,
    );
  }
}

/// Link extracted from page
class LinkInfo {
  final String url;
  final String text;

  LinkInfo({required this.url, required this.text});

  factory LinkInfo.fromJson(Map<String, dynamic> json) {
    return LinkInfo(
      url: json['url'] ?? json['href'] ?? '',
      text: json['text'] ?? '',
    );
  }
}

/// Result from search and scrape
class SearchScrapeResult {
  final String query;
  final List<ScrapeResult> results;
  final int totalResults;

  SearchScrapeResult({
    required this.query,
    required this.results,
    this.totalResults = 0,
  });

  factory SearchScrapeResult.fromJson(Map<String, dynamic> json) {
    final List results = json['results'] ?? [];
    return SearchScrapeResult(
      query: json['query'] ?? '',
      results: results.map((r) => ScrapeResult.fromJson(r)).toList(),
      totalResults: json['total_results'] ?? results.length,
    );
  }
}

/// Global scraping service instance
final scrapingService = ScrapingService();
