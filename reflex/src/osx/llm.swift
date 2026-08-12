import Foundation
import FoundationModels


@objc public enum LLMError : Int, Error
{

	case empty = 1

}// LLMError


@available(macOS 26.0, *)
@objc public class LLM : NSObject
{

	private var session: LanguageModelSession

	@objc public override init ()
	{
		self.session = LanguageModelSession()
	}

	@objc public init (instructions: String)
	{
		self.session = LanguageModelSession(instructions: instructions)
	}

	@objc public func generate (prompt: String) async throws -> String
	{
		return try await session.respond(to: prompt).content
	}

	@objc public func generateSync(prompt: String) throws -> String
	{
		let sem = DispatchSemaphore(value: 0)
		var result: Result<String, Error>?

		Task
		{
			do
			{
				result = .success(try await session.respond(to: prompt).content)
			}
			catch
			{
				result = .failure(error)
			}
			sem.signal()
		}

		sem.wait()
		guard let result = result else
		{
			throw LLMError.empty
		}
		return try result.get()
	}

}// LLM
