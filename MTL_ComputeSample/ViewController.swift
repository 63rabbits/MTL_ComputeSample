import UIKit


class ViewController: UIViewController {

    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!

    private var paramABuffer: MTLBuffer!
    private var paramBBuffer: MTLBuffer!
    private var resultBuffer: MTLBuffer!

    private var computePipeline: MTLComputePipelineState!

    private let numOfData = 100_0000

    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()

        textView.isEditable = false
        textView.isSelectable = false

        setupMetal()

        makeBuffers()

        makePipeline()

        doCompute()
    }

    private func setupMetal() {
        commandQueue = device.makeCommandQueue()
    }

    private func makeBuffers() {
        var paramA: [Float32] = []
        var paramB: [Float32] = []

        for i in (0 ..< numOfData) {
            paramA.append(Float(i))
            paramB.append(Float(i+1))
        }

        let paramSize: Int = paramA.count * MemoryLayout<Float32>.size
        paramABuffer = device.makeBuffer(bytes: paramA, length: paramSize, options: [])
        paramBBuffer = device.makeBuffer(bytes: paramB, length: paramSize, options: [])
        resultBuffer = device.makeBuffer(length: paramSize)
    }

    private func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {fatalError()}

        let function = library.makeFunction(name: "computeShader")!
        computePipeline = try! device.makeComputePipelineState(function: function)
    }


    func doCompute() {
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}



        let computeEncoder = commandBuffer.makeComputeCommandEncoder()!
        guard let computePipeline = computePipeline else {fatalError()}
        computeEncoder.setComputePipelineState(computePipeline)
        computeEncoder.setBuffer(paramABuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(paramBBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(resultBuffer, offset: 0, index: 2)



        let threadsPerGrid = MTLSize(width: numOfData, height: 1, depth: 1)
        let threadgroupSize = MTLSize(width: min(computePipeline.maxTotalThreadsPerThreadgroup, numOfData),
                                      height: 1,
                                      depth: 1)
        computeEncoder.dispatchThreads(threadsPerGrid,
                                       threadsPerThreadgroup: threadgroupSize)

        computeEncoder.endEncoding()

        commandBuffer.addCompletedHandler { cmdBuffer in
            let rawPointer = self.resultBuffer.contents()
            let typedPointer = rawPointer.bindMemory(to: Float32.self, capacity: self.numOfData)
            let bufferedPointer = UnsafeBufferPointer(start: typedPointer, count: self.numOfData)

            let gpuRuntimeDuration = commandBuffer.gpuEndTime - commandBuffer.gpuStartTime

            DispatchQueue.main.async {
                // Display the latest 100.
                self.textView.text = nil
                for i in (max(0, self.numOfData - 100) ..< self.numOfData) {
                    self.textView.insertText("[\(i)] \(bufferedPointer[i])\n")
                }
                self.textView.insertText(String(format: "\n\nrun time(sec) = %.6f", gpuRuntimeDuration))

                self.textView.scrollToBotom()
            }
        }

        commandBuffer.commit()

        commandBuffer.waitUntilCompleted()

    }
}

extension UITextView {

    func scrollToBotom() {
        let range = NSMakeRange((text as NSString).length - 1, 1);
        scrollRangeToVisible(range);
    }

}
